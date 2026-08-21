#!/usr/bin/env bash
set -euo pipefail

rofi_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
user_data="${XDG_DATA_HOME:-$HOME/.local/share}"
data_dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
current_desktop="${XDG_CURRENT_DESKTOP:-Hyprland}"
inventory="$(mktemp)"
trap 'rm -f -- "$inventory"' EXIT

declare -A classification=() seen=()

list_ids() {
    awk '
        { sub(/[[:space:]]*#.*/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, "") }
        length && !seen[$0]++ { print }
    ' "$1"
}

while IFS= read -r id; do
    classification["$id"]="SYSTEM"
done < <(list_ids "$rofi_dir/apps/system/apps.list")

while IFS= read -r id; do
    classification["$id"]="HIDDEN"
done < <(list_ids "$rofi_dir/apps/hidden/apps.list")

desktop_value() {
    local key="$1" file="$2"
    awk -F= -v key="$key" '
        /^\[Desktop Entry\]$/ { inside=1; next }
        /^\[/ && inside { exit }
        inside && $1 == key { sub(/^[^=]*=/, ""); print; exit }
    ' "$file"
}

find_packaged_entry() {
    local wanted="$1" base app_dir file rel id
    local -a bases

    IFS=: read -r -a bases <<< "$data_dirs"
    for base in "${bases[@]}"; do
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
        done < <(find "$app_dir" \( -type f -o -type l \) -name '*.desktop' -print0)
    done
    return 1
}

desktop_is_listed() {
    local desktop_list="$1" candidate
    local -a desktops

    IFS=: read -r -a desktops <<< "$current_desktop"
    for candidate in "${desktops[@]}"; do
        [[ ";$desktop_list" == *";$candidate;"* ]] && return 0
    done
    return 1
}

emit_entry() {
    local id="$1" effective="$2"
    local class source original name generic comment exec categories
    local hidden nodisplay only_show not_show try_exec reason order

    class="${classification[$id]:-}"
    source="$effective"
    original="$(desktop_value X-Rofi-Source "$effective")"
    if [[ -n "$class" ]]; then
        if [[ -n "$original" && -f "$original" ]]; then
            source="$original"
        else
            source="$(find_packaged_entry "$id" || printf '%s' "$effective")"
        fi
    fi

    name="$(desktop_value Name "$source")"
    name="${name#$'⁣'}"
    generic="$(desktop_value GenericName "$source")"
    comment="$(desktop_value Comment "$source")"
    exec="$(desktop_value Exec "$source")"
    categories="$(desktop_value Categories "$source")"
    hidden="$(desktop_value Hidden "$effective")"
    nodisplay="$(desktop_value NoDisplay "$effective")"
    only_show="$(desktop_value OnlyShowIn "$source")"
    not_show="$(desktop_value NotShowIn "$source")"
    try_exec="$(desktop_value TryExec "$source")"

    if [[ "$class" == "SYSTEM" ]]; then
        reason="explicitly listed in apps/system/apps.list"
    elif [[ "$class" == "HIDDEN" ]]; then
        reason="explicitly listed in apps/hidden/apps.list"
    elif [[ "$hidden" == "true" ]]; then
        class="HIDDEN"
        reason="automatic: Hidden=true"
    elif [[ "$nodisplay" == "true" ]]; then
        class="HIDDEN"
        reason="automatic: NoDisplay=true"
    elif [[ -n "$only_show" ]] && ! desktop_is_listed "$only_show"; then
        class="HIDDEN"
        reason="automatic: OnlyShowIn=$only_show"
    elif [[ -n "$not_show" ]] && desktop_is_listed "$not_show"; then
        class="HIDDEN"
        reason="automatic: NotShowIn=$not_show"
    elif [[ -n "$try_exec" && "$try_exec" == /* && ! -x "$try_exec" ]]; then
        class="HIDDEN"
        reason="automatic: unavailable TryExec=$try_exec"
    elif [[ -n "$try_exec" && "$try_exec" != /* ]] && ! command -v "$try_exec" >/dev/null 2>&1; then
        class="HIDDEN"
        reason="automatic: unavailable TryExec=$try_exec"
    else
        class="NORMAL"
        reason="visible in the $current_desktop application set"
    fi

    [[ -n "$name" ]] || name="$id"
    case "$class" in
        NORMAL) order=1 ;;
        SYSTEM) order=2 ;;
        HIDDEN) order=3 ;;
    esac

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$order" "$name" "$id" "${generic:--}" "${comment:--}" \
        "${exec:--}" "${categories:--}" "$reason" "$class" >> "$inventory"
}

IFS=: read -r -a data_bases <<< "$user_data:$data_dirs"
for base in "${data_bases[@]}"; do
    base="${base%/}"
    app_dir="$base/applications"
    [[ -d "$app_dir" ]] || continue
    while IFS= read -r -d '' file; do
        rel="${file#"$app_dir/"}"
        id="${rel//\//-}"
        [[ "${seen[$id]+yes}" ]] && continue
        seen["$id"]=1
        emit_entry "$id" "$file"
    done < <(find "$app_dir" \( -type f -o -type l \) -name '*.desktop' -print0)
done

printf '# Application classification inventory\n\n'
printf 'Generated from the effective XDG desktop-entry set for `%s`. User entries take precedence over package entries.\n\n' "$current_desktop"
printf 'Scope: every application desktop entry Rofi could discover through the configured XDG data directories, including Snap entries and automatically suppressed helpers. This is not a list of command-line-only packages.\n\n'
printf 'The classification is the current state, not a recommendation. “Automatic” HIDDEN entries are suppressed by their own desktop metadata rather than by the Rofi lists.\n\n'

current_class=""
while IFS=$'\t' read -r _ name id generic comment exec categories reason class; do
    if [[ "$class" != "$current_class" ]]; then
        [[ -z "$current_class" ]] || printf '\n'
        current_class="$class"
        printf '## %s\n\n' "$class"
    fi
    printf -- '- %s — ID: `%s`; GenericName: %s; Comment: %s; Exec: `%s`; Categories: `%s`; Status: %s.\n' \
        "$name" "$id" "$generic" "$comment" "$exec" "$categories" "$reason"
done < <(sort -t $'\t' -k1,1n -k2,2f "$inventory")

printf '\n## Counts\n\n'
for class in NORMAL SYSTEM HIDDEN; do
    count="$(awk -F '\t' -v class="$class" '$9 == class { count++ } END { print count+0 }' "$inventory")"
    printf -- '- %s: %s\n' "$class" "$count"
done
