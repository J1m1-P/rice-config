#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rice-theme"
profiles_dir="$config_dir/profiles"
selector_dir="$config_dir/selectors"
current_file="$selector_dir/profile"
default_file="$config_dir/default-profile"
components=(hyprland waybar swaync rofi kitty)

usage() {
    printf 'Usage:\n  rice-theme help\n  rice-theme current\n  rice-theme list\n  rice-theme default\n  rice-theme NAME\n'
}

list_profiles() {
    find "$profiles_dir" -maxdepth 1 -type f -printf '%f\n' | sort
}

read_profile() {
    local profile="$1" line key value
    declare -gA selected=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        [[ "$line" == *=* ]] || return 1
        key=${line%%=*}
        value=${line#*=}
        [[ " ${components[*]} " == *" $key "* && -z "${selected[$key]+set}" ]] || return 1
        [[ "$value" =~ ^[A-Za-z0-9_-]+$ ]] || return 1
        selected[$key]=$value
    done < "$profiles_dir/$profile"
    for key in "${components[@]}"; do
        [[ -n "${selected[$key]:-}" ]] || return 1
    done
}

current_profile() {
    local profile component component_command actual mismatch=0
    [[ -r "$current_file" ]] || { printf 'No desktop profile is selected.\n' >&2; return 1; }
    IFS= read -r profile < "$current_file"
    [[ -r "$profiles_dir/$profile" ]] && read_profile "$profile" || {
        printf 'Selected desktop profile is invalid: %s\n' "$profile" >&2
        return 1
    }
    printf '%s\n' "$profile"
    for component in "${components[@]}"; do
        component_command="${component}-theme"
        actual=$("$component_command" current 2>/dev/null || true)
        if [[ "$actual" != "${selected[$component]}" ]]; then
            printf '  %-10s expected %-20s current %s\n' "$component" "${selected[$component]}" "${actual:-none}"
            mismatch=1
        fi
    done
    (( mismatch == 0 )) || return 1
}

(( $# == 1 )) || { usage >&2; exit 2; }
case "$1" in
    help|-h|--help) usage; exit ;;
    current) current_profile; exit ;;
    list) list_profiles; exit ;;
    default) IFS= read -r profile < "$default_file" ;;
    *) profile="$1" ;;
esac

[[ "$profile" =~ ^[A-Za-z0-9_-]+$ && -r "$profiles_dir/$profile" ]] || {
    printf 'Unknown desktop profile: %s\n' "$profile" >&2
    exit 1
}
read_profile "$profile" || {
    printf 'Invalid desktop profile: %s\n' "$profile" >&2
    exit 1
}

printf 'Validating %s...\n\n' "$profile"
valid=true
for component in "${components[@]}"; do
    component_command="${component}-theme"
    if ! command -v "$component_command" >/dev/null 2>&1; then
        printf '%-10s %-20s ✗ helper unavailable\n' "$component" "${selected[$component]}"
        valid=false
    elif ! available=$("$component_command" list 2>&1); then
        printf '%-10s %-20s ✗ helper failed\n' "$component" "${selected[$component]}"
        [[ -z "$available" ]] || printf '  %s\n' "$available" >&2
        valid=false
    elif ! grep -Fxq -- "${selected[$component]}" <<< "$available"; then
        printf '%-10s %-20s ✗ missing\n' "$component" "${selected[$component]}"
        valid=false
    elif validation_output=$(RICE_THEME_CHECK=1 "$component_command" "${selected[$component]}" 2>&1); then
        printf '%-10s %-20s ✓\n' "$component" "${selected[$component]}"
    else
        printf '%-10s %-20s ✗ invalid\n' "$component" "${selected[$component]}"
        [[ -z "$validation_output" ]] || printf '  %s\n' "$validation_output" >&2
        valid=false
    fi
done
if [[ "$valid" != true ]]; then
    printf '\nTheme not applied.\n' >&2
    exit 1
fi

printf '\nApplying %s...\n' "$profile"
for component in "${components[@]}"; do
    component_command="${component}-theme"
    "$component_command" "${selected[$component]}"
done
tmp=$(mktemp "$selector_dir/.profile.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf '%s\n' "$profile" > "$tmp"
mv -- "$tmp" "$current_file"
trap - EXIT
printf 'Activated desktop profile: %s\n' "$profile"
