#!/usr/bin/env bash

set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_home/swaync"
themes_dir="$config_dir/themes"
selector_dir="$config_home/rice-theme/selectors"
selector="$selector_dir/swaync.css"
default_file="$config_dir/default-theme"

usage() {
    printf 'Usage:\n  swaync-theme help\n  swaync-theme current\n  swaync-theme list\n  swaync-theme default\n  swaync-theme NAME\n'
}

list_themes() {
    find "$themes_dir" -maxdepth 1 -type f -name '*.css' -printf '%f\n' | sed 's/\.css$//' | sort
}

current_theme() {
    local name
    [[ -r "$selector" ]] || { printf 'No SwayNC theme is selected.\n' >&2; return 1; }
    name=$(sed -n 's|^@import url("../../swaync/themes/\([A-Za-z0-9_-]*\)\.css");$|\1|p' "$selector")
    [[ "$name" =~ ^[A-Za-z0-9_-]+$ && -r "$themes_dir/$name.css" ]] || {
        printf 'Invalid SwayNC selector: %s\n' "$selector" >&2
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

[[ "$name" =~ ^[A-Za-z0-9_-]+$ && -r "$themes_dir/$name.css" ]] || {
    printf 'Unknown SwayNC theme: %s\n' "$name" >&2
    exit 1
}
if command -v python3 >/dev/null 2>&1 &&
   python3 -c 'import gi; gi.require_version("Gtk", "4.0"); from gi.repository import Gtk' >/dev/null 2>&1; then
    python3 -c 'import gi, sys; gi.require_version("Gtk", "4.0"); from gi.repository import Gtk; p = Gtk.CssProvider(); p.load_from_path(sys.argv[1])' "$themes_dir/$name.css"
fi
[[ "${RICE_THEME_CHECK:-0}" == 1 ]] && exit

tmp=$(mktemp "$selector_dir/.swaync.css.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
printf '@import url("../../swaync/themes/%s.css");\n' "$name" > "$tmp"
mv -- "$tmp" "$selector"
trap - EXIT

if pgrep -x swaync >/dev/null 2>&1 && swaync-client --reload-css >/dev/null 2>&1; then
    printf 'Activated and reloaded SwayNC theme: %s\n' "$name"
else
    printf 'Activated SwayNC theme: %s (no running SwayNC instance to reload)\n' "$name"
fi
