#!/usr/bin/env bash
set -euo pipefail
rofi_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
themes_dir="$rofi_dir/themes"
link="$rofi_dir/current-theme.rasi"
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 THEME_NAME" >&2
    echo "Available themes:" >&2
    find "$themes_dir" -mindepth 1 -maxdepth 1 -type d ! -name _template -printf '  %f\n' | sort >&2
    exit 2
fi
name="$1"
target="$themes_dir/$name/theme.rasi"
# Reject path traversal and names that could escape the themes directory.
if [[ "$name" == */* || "$name" == .* || "$name" == _template ]]; then
    echo "Invalid theme name: $name" >&2
    exit 1
fi
if [[ ! -f "$target" ]]; then
    echo "Theme not found: $name" >&2
    echo "Expected: $target" >&2
    exit 1
fi
# A relative link keeps the configuration portable if the rofi directory moves.
ln -sfn "themes/$name/theme.rasi" "$link"
echo "Activated theme: $name"
