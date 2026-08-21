#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROFI_APP_GROUP=system exec "$script_dir/hidden-apps.sh" "$@"
