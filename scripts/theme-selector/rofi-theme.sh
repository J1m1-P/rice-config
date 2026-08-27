#!/usr/bin/env bash
set -euo pipefail
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
rofi_dir="$config_home/rofi"
themes_dir="$rofi_dir/themes"
selector_dir="$config_home/rice-theme/selectors"
link="$selector_dir/rofi.rasi"
default_file="$rofi_dir/default-theme"

list_themes() {
    find "$themes_dir" -mindepth 1 -maxdepth 1 -type d ! -name _template -printf '%f\n' | sort
}

usage() {
    printf 'Usage:\n  rofi-theme help\n  rofi-theme current\n  rofi-theme list\n  rofi-theme default\n  rofi-theme NAME\n'
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 2
fi

case "$1" in
    help|-h|--help)
        usage
        exit
        ;;
    current)
        [[ -r "$link" ]] || { echo 'No Rofi theme is selected; run setup.sh or rofi-theme default.' >&2; exit 1; }
        theme_path=$(sed -n 's/^@theme[[:space:]]*"\(.*\)"$/\1/p' "$link")
        [[ -n "$theme_path" ]] || { echo "Invalid Rofi selector: $link" >&2; exit 1; }
        name=$(basename "$(dirname "$theme_path")")
        [[ "$name" =~ ^[A-Za-z0-9_-]+$ && "$(readlink -f -- "$theme_path" 2>/dev/null)" == "$(readlink -f -- "$themes_dir/$name/theme.rasi" 2>/dev/null)" ]] || {
            echo "Invalid Rofi selector: $link" >&2
            exit 1
        }
        printf '%s\n' "$name"
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
if command -v rofi >/dev/null 2>&1; then
    rofi -theme "$target" -dump-theme >/dev/null
fi
[[ "${RICE_THEME_CHECK:-0}" == 1 ]] && exit
temp=$(mktemp "$selector_dir/.rofi.rasi.XXXXXX")
trap 'rm -f -- "$temp"' EXIT
# Rofi 2.0 resolves nested imports reliably when the selected theme is loaded
# by absolute path. This generated file is local state, not portable source.
printf '@theme "%s"\n' "$target" > "$temp"
mv -- "$temp" "$link"
trap - EXIT
echo "Activated theme: $name"
