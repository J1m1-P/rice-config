#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
selector="$config_dir/current-theme.conf"
themes_dir="$config_dir/themes"

usage() {
    printf 'Usage: %s {current|list|minimum-black|stealth|kitty-default}\n' "$0"
}

list_themes() {
    local theme
    shopt -s nullglob
    for theme in "$themes_dir"/*.conf; do
        basename "$theme" .conf
    done
}

current_theme() {
    awk '$1 == "include" && $2 ~ /^themes\// { sub(/^themes\//, "", $2); sub(/\.conf$/, "", $2); print $2; exit }' "$selector"
}

if (( $# != 1 )); then
    usage >&2
    exit 2
fi

case "$1" in
    current)
        current_theme
        exit
        ;;
    list)
        list_themes
        exit
        ;;
    -h|--help)
        usage
        exit
        ;;
esac

theme_name=${1%.conf}
if [[ "$theme_name" == *[!A-Za-z0-9_-]* || ! -f "$themes_dir/$theme_name.conf" ]]; then
    printf 'Unknown theme: %s\n\nAvailable themes:\n' "$1" >&2
    list_themes >&2
    exit 1
fi

# Validate the complete configuration before changing the selector.
if ! KITTY_CONFIG_TO_CHECK="$config_dir/kitty.conf" kitty +runpy '
import os
import sys
from kitty.config import load_config

bad_lines = []
load_config(os.environ["KITTY_CONFIG_TO_CHECK"], accumulate_bad_lines=bad_lines)
for bad_line in bad_lines:
    print(bad_line, file=sys.stderr)
sys.exit(bool(bad_lines))
'; then
    printf 'Configuration validation failed; the active theme was not changed.\n' >&2
    exit 1
fi

temp_selector=$(mktemp "$config_dir/.current-theme.conf.XXXXXX")
trap 'rm -f "$temp_selector"' EXIT
printf '%s\n' '# Active theme; managed by kitty-profile.sh.' "include themes/$theme_name.conf" > "$temp_selector"
mv "$temp_selector" "$selector"
trap - EXIT

# SIGUSR1 is Kitty's built-in config reload signal. Prefer the parent Kitty
# exported to shells; fall back to detected Kitty GUI processes for external use.
kitty_pids=()
if [[ "${KITTY_PID:-}" =~ ^[1-9][0-9]*$ ]] && kill -0 "$KITTY_PID" 2>/dev/null; then
    kitty_pids=("$KITTY_PID")
else
    mapfile -t kitty_pids < <(pgrep -x kitty 2>/dev/null || true)
fi

reloaded=0
for kitty_pid in "${kitty_pids[@]}"; do
    if kill -USR1 "$kitty_pid" 2>/dev/null; then
        reloaded=1
    fi
done

if (( reloaded )); then
    printf 'Activated and reloaded Kitty theme: %s\n' "$theme_name"
else
    printf 'Activated theme but no running Kitty process was reloaded: %s\n' "$theme_name" >&2
    printf '%s\n' 'Start Kitty or press Ctrl+Shift+F5 to load it.' >&2
    exit 1
fi
