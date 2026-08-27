#!/usr/bin/env bash

set -euo pipefail
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_home/waybar"
themes_dir="$config_dir/themes"
selector_dir="$config_home/rice-theme/selectors"
selector="$selector_dir/waybar.css"
default_file="$config_dir/default-theme"

usage() { printf 'Usage:\n  waybar-theme help\n  waybar-theme current\n  waybar-theme list\n  waybar-theme default\n  waybar-theme NAME\n'; }
list_themes() { find "$themes_dir" -maxdepth 1 -type f -name '*.css' -printf '%f\n' | sed 's/\.css$//' | sort; }
current_theme() {
    local name
    [[ -r "$selector" ]] || { printf 'No Waybar theme is selected.\n' >&2; return 1; }
    name=$(sed -n 's|^@import url("../../waybar/themes/\([A-Za-z0-9_-]*\)\.css");$|\1|p' "$selector")
    [[ "$name" =~ ^[A-Za-z0-9_-]+$ && -r "$themes_dir/$name.css" ]] || {
        printf 'Invalid Waybar selector: %s\n' "$selector" >&2
        return 1
    }
    printf '%s\n' "$name"
}
[[ $# -eq 1 ]] || { usage >&2; exit 2; }
case "$1" in
    help|-h|--help) usage; exit ;;
    current) current_theme; exit ;;
    list) list_themes; exit ;;
esac
name="$1"
[[ "$name" == default ]] && name=$(<"$default_file")
[[ "$name" =~ ^[A-Za-z0-9_-]+$ && -f "$themes_dir/$name.css" ]] || { printf 'Unknown Waybar theme: %s\n' "$name" >&2; exit 1; }
if command -v python3 >/dev/null 2>&1 &&
   python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' >/dev/null 2>&1; then
    python3 -c 'import gi, sys; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk; p = Gtk.CssProvider(); p.load_from_path(sys.argv[1])' "$themes_dir/$name.css"
fi
[[ "${RICE_THEME_CHECK:-0}" == 1 ]] && exit
tmp=$(mktemp "$selector_dir/.waybar.css.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf '@import url("../../waybar/themes/%s.css");\n' "$name" > "$tmp"
mv -- "$tmp" "$selector"
trap - EXIT
pkill -USR2 -x waybar 2>/dev/null || true
printf 'Activated Waybar theme: %s\n' "$name"
