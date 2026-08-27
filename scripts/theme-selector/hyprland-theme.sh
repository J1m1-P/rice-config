#!/usr/bin/env bash

set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_home/hypr"
themes_dir="$config_dir/themes"
selector_dir="$config_home/rice-theme/selectors"
selector="$selector_dir/hyprland.conf"
default_file="$config_dir/default-theme"

usage() {
    printf 'Usage:\n  hyprland-theme help\n  hyprland-theme current\n  hyprland-theme list\n  hyprland-theme default\n  hyprland-theme NAME\n'
}

list_themes() {
    find "$themes_dir" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' | sed 's/\.conf$//' | sort
}

current_theme() {
    local name
    [[ -r "$selector" ]] || { printf 'No Hyprland theme is selected.\n' >&2; return 1; }
    name=$(sed -n 's|^[[:space:]]*source[[:space:]]*=[[:space:]]*.*themes/\([A-Za-z0-9_-]*\)\.conf[[:space:]]*$|\1|p' "$selector")
    [[ "$name" =~ ^[A-Za-z0-9_-]+$ && -r "$themes_dir/$name.conf" ]] || {
        printf 'Invalid Hyprland selector: %s\n' "$selector" >&2
        return 1
    }
    printf '%s\n' "$name"
}

(( $# == 1 )) || { usage >&2; exit 2; }
case "$1" in
    help|-h|--help) usage; exit ;;
    current) current_theme; exit ;;
    list) list_themes; exit ;;
    default) IFS= read -r name < "$default_file" ;;
    *) name="$1" ;;
esac

[[ "$name" =~ ^[A-Za-z0-9_-]+$ && -r "$themes_dir/$name.conf" ]] || {
    printf 'Unknown Hyprland theme: %s\n' "$name" >&2
    exit 1
}

if command -v Hyprland >/dev/null 2>&1; then
    check_config=$(mktemp "$config_dir/.hyprland-theme-check.XXXXXX")
    trap 'rm -f -- "$check_config"' EXIT
    awk -v theme="$themes_dir/$name.conf" '
        /^[[:space:]]*source[[:space:]]*=[[:space:]]*.*rice-theme\/selectors\/hyprland\.conf/ { print "source = " theme; next }
        { print }
    ' "$config_dir/hyprland.conf" > "$check_config"
    Hyprland --verify-config --config "$check_config" >/dev/null
    rm -f -- "$check_config"
    trap - EXIT
fi
[[ "${RICE_THEME_CHECK:-0}" == 1 ]] && exit

tmp=$(mktemp "$selector_dir/.hyprland.conf.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf 'source = %s/themes/%s.conf\n' "$config_dir" "$name" > "$tmp"
mv -- "$tmp" "$selector"
trap - EXIT

if command -v Hyprland >/dev/null 2>&1; then
    Hyprland --verify-config --config "$config_dir/hyprland.conf" >/dev/null
fi

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null; then
    printf 'Activated and reloaded Hyprland theme: %s\n' "$name"
else
    printf 'Activated Hyprland theme: %s (reload applies in a Hyprland session)\n' "$name"
fi
