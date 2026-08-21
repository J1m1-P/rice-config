#!/usr/bin/env bash
set -euo pipefail

rofi_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
user_data="${XDG_DATA_HOME:-$HOME/.local/share}"
user_apps="$user_data/applications"
app_group="${ROFI_APP_GROUP:-hidden}"

case "$app_group" in
    hidden)
        menu_title="Hidden"
        add_label="Add Hidden Application"
        remove_label="Remove Hidden Application"
        ;;
    system)
        menu_title="System"
        add_label="Add System Application"
        remove_label="Remove System Application"
        ;;
    *)
        printf 'Unsupported application group: %s\n' "$app_group" >&2
        exit 2
        ;;
esac

state_dir="$rofi_dir/apps/.$app_group-apps"
hidden_list="$rofi_dir/apps/$app_group/apps.list"

list_ids() {
    awk '
        { sub(/[[:space:]]*#.*/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, "") }
        length && !seen[$0]++ { print }
    ' "$1"
}

is_listed() {
    local wanted="$1" id
    while IFS= read -r id; do
        [[ "$id" == "$wanted" ]] && return 0
    done < <(list_ids "$hidden_list")
    return 1
}

add_to_list() {
    local id="$1" name="$2"
    is_listed "$id" && return 0
    printf '%s # %s\n' "$id" "$name" >> "$hidden_list"
}

remove_from_list() {
    local wanted="$1" tmp
    tmp="$(mktemp "$hidden_list.XXXXXX")"
    awk -v wanted="$wanted" '
        {
            entry = $0
            sub(/[[:space:]]*#.*/, "", entry)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", entry)
        }
        entry != wanted { print }
    ' "$hidden_list" > "$tmp"
    mv -- "$tmp" "$hidden_list"
}

desktop_value() {
    awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$2"
}

find_original() {
    local wanted="$1" base app_dir file rel id
    local -a data_dirs

    IFS=: read -r -a data_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for base in "${data_dirs[@]}"; do
        base="${base%/}"
        app_dir="$base/applications"
        [[ -d "$app_dir" ]] || continue
        while IFS= read -r -d '' file; do
            rel="${file#"$app_dir/"}"
            id="${rel//\//-}"
            if [[ "$id" == "$wanted" ]]; then
                printf '%s\n' "$file"
                return 0
            fi
        done < <(find "$app_dir" -type f -name '*.desktop' -print0)
    done
    return 1
}

list_visible() {
    local base app_dir file rel id name icon
    local -a data_dirs
    local -A seen=()

    IFS=: read -r -a data_dirs <<< "$user_data:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for base in "${data_dirs[@]}"; do
        base="${base%/}"
        app_dir="$base/applications"
        [[ -d "$app_dir" ]] || continue
        while IFS= read -r -d '' file; do
            rel="${file#"$app_dir/"}"
            id="${rel//\//-}"
            [[ "${seen[$id]+yes}" ]] && continue
            [[ "$id" == "rofi-hidden-applications.desktop" || "$id" == "rofi-system-applications.desktop" ]] && continue
            seen["$id"]=1
            grep -Eq '^(Hidden|NoDisplay)=true$' "$file" && continue
            name="$(desktop_value Name "$file")"
            icon="$(desktop_value Icon "$file")"
            [[ -n "$name" ]] && printf '%s\t%s\t%s\t%s\n' "$name" "$id" "$file" "${icon:-application-x-executable}"
        done < <(find "$app_dir" -type f -name '*.desktop' -print0)
    done
}

list_hidden() {
    local file name id source icon
    [[ -f "$hidden_list" ]] || return 0
    while IFS= read -r id; do
        file="$user_apps/$id"
        source=""
        [[ -f "$file" ]] && source="$(desktop_value X-Rofi-Source "$file")"
        [[ -f "$source" ]] || source="$(find_original "$id" || true)"
        name=""
        icon=""
        [[ -f "$file" ]] && name="$(desktop_value Name "$file")"
        [[ -f "$file" ]] && icon="$(desktop_value X-Rofi-Icon "$file")"
        [[ -n "$name" ]] || [[ ! -f "$source" ]] || name="$(desktop_value Name "$source")"
        if [[ -z "$icon" && -f "$source" ]]; then
            icon="$(desktop_value Icon "$source")"
        fi
        printf '%s\t%s\t%s\t%s\n' "${name:-$id}" "$id" "$source" "${icon:-application-x-executable}"
    done < <(list_ids "$hidden_list")
}

visible_rows() {
    local name id source icon
    while IFS=$'\t' read -r name id source icon; do
        printf '%s\t%s\t%s\0icon\x1f%s\n' "$name" "$id" "$source" "$icon"
    done < <(list_visible | sort -f)
}

hidden_rows() {
    local name id source icon
    while IFS=$'\t' read -r name id source icon; do
        printf '%s\t%s\t%s\0icon\x1f%s\n' "$name" "$id" "$source" "$icon"
    done < <(list_hidden | sort -f)
}

write_hidden_override() {
    local id="$1" source="$2"
    local name icon override backup path_file launch_source tmp
    name="$(desktop_value Name "$source")"
    icon="$(desktop_value Icon "$source")"
    mkdir -p "$user_apps" "$state_dir/backups" "$state_dir/paths"
    override="$user_apps/$id"
    backup="$state_dir/backups/$id"
    path_file="$state_dir/paths/$id"
    launch_source="$source"

    # Preserve an existing user desktop file so restoring is lossless.
    if [[ "$source" == "$user_apps/"* ]]; then
        mv -- "$source" "$backup"
        printf '%s\n' "$source" > "$path_file"
        launch_source="$backup"
    fi

    tmp="$(mktemp "$user_apps/.rofi-group.XXXXXX")"
    printf '[Desktop Entry]\nType=Application\nName=%s\nHidden=true\nX-Rofi-Group=%s\nX-Rofi-Source=%s\nX-Rofi-Icon=%s\n' \
        "$name" "$app_group" "$launch_source" "$icon" > "$tmp"
    mv -- "$tmp" "$override"
}

repair_backup_source() {
    local id="$1" override backup current tmp
    override="$user_apps/$id"
    backup="$state_dir/backups/$id"
    [[ -f "$override" && -f "$backup" ]] || return 0
    current="$(desktop_value X-Rofi-Source "$override")"
    [[ "$current" == "$backup" ]] && return 0

    tmp="$(mktemp "$user_apps/.rofi-group.XXXXXX")"
    awk -v source="$backup" '
        /^X-Rofi-Source=/ { print "X-Rofi-Source=" source; found=1; next }
        { print }
        END { if (!found) print "X-Rofi-Source=" source }
    ' "$override" > "$tmp"
    mv -- "$tmp" "$override"
}

hide_app() {
    local choice name id source
    choice="$({
        printf 'Return to %s Applications\t__return__\t\0icon\x1fgo-previous-symbolic\n' "$menu_title"
        visible_rows
    } | rofi -dmenu -i -show-icons -p "$add_label" -display-columns 1)"
    [[ -n "$choice" ]] || return 0
    IFS=$'\t' read -r name id source <<< "$choice"
    [[ "$id" == "__return__" ]] && return 0

    write_hidden_override "$id" "$source"
    add_to_list "$id" "$name — assigned to $app_group applications"
}

restore_override() {
    local id="$1" override backup path_file original
    override="$user_apps/$id"
    backup="$state_dir/backups/$id"
    path_file="$state_dir/paths/$id"

    [[ -f "$override" ]] || return 0
    grep -Eq '^(Hidden|X-Rofi-Hidden)=true$' "$override" || return 0
    rm -- "$override"
    if [[ -f "$backup" && -f "$path_file" ]]; then
        original="$(<"$path_file")"
        mkdir -p "${original%/*}"
        mv -- "$backup" "$original"
        rm -- "$path_file"
    fi
}

restore_id() {
    local id="$1"
    restore_override "$id"
    remove_from_list "$id"
}

sync_hidden() {
    local id source override
    mkdir -p "$user_apps" "$state_dir/backups" "$state_dir/paths"

    while IFS= read -r id; do
        override="$user_apps/$id"
        if grep -Eq '^(Hidden|NoDisplay)=true$' "$override" 2>/dev/null; then
            repair_backup_source "$id"
            continue
        fi
        if [[ -f "$override" ]]; then
            source="$override"
        else
            source="$(find_original "$id" || true)"
        fi
        [[ -f "$source" ]] || continue
        write_hidden_override "$id" "$source"
    done < <(list_ids "$hidden_list")

    while IFS= read -r -d '' override; do
        if ! grep -qx "X-Rofi-Group=$app_group" "$override"; then
            [[ "$app_group" == "hidden" ]] && grep -qx 'X-Rofi-Hidden=true' "$override" || continue
        fi
        id="${override##*/}"
        is_listed "$id" || restore_override "$id"
    done < <(find "$user_apps" -maxdepth 1 -type f -name '*.desktop' -print0)
}

restore_app() {
    local choice id
    choice="$({
        printf 'Return to %s Applications\t__return__\t\0icon\x1fgo-previous-symbolic\n' "$menu_title"
        hidden_rows
    } | rofi -dmenu -i -show-icons -p "$remove_label" -display-columns 1)"
    [[ -n "$choice" ]] || return 0
    IFS=$'\t' read -r _ id _ <<< "$choice"
    [[ "$id" == "__return__" ]] && return 0
    restore_id "$id"
}

run_hidden() {
    local source="$1"
    if [[ -f "$source" ]] && gio launch "$source" >/dev/null; then
        return 0
    fi
    rofi -e "Could not launch $app_group application."
}

main_menu() {
    local choice action source name id icon
    sync_hidden
    while true; do
        choice="$({
            printf 'Return to Applications\t__return__\0icon\x1fgo-previous-symbolic\n'
            printf '%s\t__hide__\0icon\x1flist-add-symbolic\n' "$add_label"
            printf '%s\t__restore__\0icon\x1flist-remove-symbolic\n' "$remove_label"
            while IFS=$'\t' read -r name id source icon; do
                printf '%s\t__run__\t%s\0icon\x1f%s\n' "$name" "$source" "$icon"
            done < <(list_hidden | sort -f)
        } | rofi -dmenu -i -show-icons -p "$menu_title" -display-columns 1)"
        [[ -n "$choice" ]] || return 0

        IFS=$'\t' read -r _ action source <<< "$choice"
        case "$action" in
            __return__) exec rofi -show drun -show-icons ;;
            __hide__) hide_app ;;
            __restore__) restore_app ;;
            __run__) run_hidden "$source"; return 0 ;;
        esac
    done
}

case "${1:-menu}" in
    add|hide) hide_app ;;
    remove|restore) restore_app ;;
    sync) sync_hidden ;;
    menu) main_menu ;;
    *) printf 'Usage: %s [menu|add|remove|sync]\n' "$0" >&2; exit 2 ;;
esac
