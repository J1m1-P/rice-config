#!/usr/bin/env bash
set -euo pipefail
rofi_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
themes_dir="$rofi_dir/themes"
link="$rofi_dir/local-theme.rasi"
default_file="$rofi_dir/default-theme"

list_themes() {
    find "$themes_dir" -mindepth 1 -maxdepth 1 -type d ! -name _template -printf '%f\n' | sort
}

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 {current|list|default|THEME_NAME}" >&2
    echo "Available themes:" >&2
    list_themes | sed 's/^/  /' >&2
    exit 2
fi

case "$1" in
    current)
        [[ -r "$link" ]] || { echo 'No Rofi theme is selected; run setup.sh or rofi-theme default.' >&2; exit 1; }
        theme_path=$(sed -n 's/^@theme[[:space:]]*"\(.*\)"$/\1/p' "$link")
        [[ -n "$theme_path" ]] || { echo "Invalid Rofi selector: $link" >&2; exit 1; }
        basename "$(dirname "$theme_path")"
        exit
        ;;
    list)
        list_themes
        exit
        ;;
    default)
        [[ -r "$default_file" ]] || { echo "Missing default theme declaration: $default_file" >&2; exit 1; }
        IFS= read -r name < "$default_file"
        ;;
    *)
        name="$1"
        ;;
esac
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
temp=$(mktemp "$rofi_dir/.local-theme.rasi.XXXXXX")
trap 'rm -f -- "$temp"' EXIT
# Rofi 2.0 resolves nested imports reliably when the selected theme is loaded
# by absolute path. This generated file is local state, not portable source.
printf '@theme "%s"\n' "$target" > "$temp"
mv -- "$temp" "$link"
trap - EXIT
echo "Activated theme: $name"
