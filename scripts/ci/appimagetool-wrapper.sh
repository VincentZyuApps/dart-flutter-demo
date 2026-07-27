#!/usr/bin/env bash
set -euo pipefail

app_dir=""
for argument in "$@"; do
  if [[ -d "$argument" && -f "$argument/AppRun" ]]; then
    app_dir="$argument"
    break
  fi
done

if [[ -z "$app_dir" ]]; then
  echo "Unable to locate an AppDir argument containing AppRun." >&2
  exit 64
fi

rm -f -- "$app_dir/usr/lib/libstdc++.so.6" "$app_dir/usr/lib/libgcc_s.so.1"
exec "${APPIMAGETOOL_REAL:-/usr/local/bin/appimagetool.real}" "$@"
