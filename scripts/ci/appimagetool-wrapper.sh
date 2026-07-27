#!/usr/bin/env bash
set -euo pipefail

app_dir="${1:?AppDir path is required}"
rm -f "$app_dir/usr/lib/libstdc++.so.6" "$app_dir/usr/lib/libgcc_s.so.1"
exec /usr/local/bin/appimagetool.real "$@"
