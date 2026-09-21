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

# The AppImage maker has no setting for the window class, so the entry is
# completed here: without it the dock cannot match the running GTK window with
# the launcher and adds a second, unnamed icon.
for entry in "$app_dir"/*.desktop; do
  if [[ -f "$entry" ]] && ! grep -q '^StartupWMClass=' "$entry"; then
    printf 'StartupWMClass=io.github.vincentzyuapps.dartflutterdemo\n' >> "$entry"
  fi
done

exec "${APPIMAGETOOL_REAL:-/usr/local/bin/appimagetool.real}" "$@"
