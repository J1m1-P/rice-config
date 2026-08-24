#!/usr/bin/env bash

set -euo pipefail
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
themes_dir="$config_dir/themes"
selector="$config_dir/local-theme.css"
default_file="$config_dir/default-theme"

list_themes() { find "$themes_dir" -maxdepth 1 -type f -name '*.css' -printf '%f\n' | sed 's/\.css$//' | sort; }
[[ $# -eq 1 ]] || { printf 'Usage: waybar-theme {list|default|THEME_NAME}\n' >&2; exit 2; }
[[ "$1" == list ]] && { list_themes; exit 0; }
name="$1"
[[ "$name" == default ]] && name=$(<"$default_file")
[[ "$name" =~ ^[A-Za-z0-9_-]+$ && -f "$themes_dir/$name.css" ]] || { printf 'Unknown Waybar theme: %s\n' "$name" >&2; exit 1; }
tmp=$(mktemp "$config_dir/.local-theme.css.XXXXXX")
printf '@import url("themes/%s.css");\n' "$name" > "$tmp"
mv -- "$tmp" "$selector"
pkill -USR2 -x waybar 2>/dev/null || true
printf 'Activated Waybar theme: %s\n' "$name"
