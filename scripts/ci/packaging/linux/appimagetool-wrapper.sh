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

# Window class of the GTK window, see linux/runner/my_application.cc. The
# AppImage maker has no setting for it, and without the key the dock cannot
# match the running window with the launcher, so it adds a second, unnamed icon.
STARTUP_WM_CLASS='StartupWMClass=io.github.vincentzyuapps.dartflutterdemo'
DESKTOP_FILENAME='io.github.vincentzyuapps.dartflutterdemo.desktop'

# The generated entry ends with its [Desktop Action ...] groups, so the key has
# to be inserted into [Desktop Entry]. Appending it would describe the last
# action group instead of the application, and the key would be ignored.
desktop_entries=("$app_dir"/*.desktop)
if [[ ! -f "${desktop_entries[0]:-}" || ${#desktop_entries[@]} -ne 1 ]]; then
  echo "Expected exactly one desktop entry in $app_dir." >&2
  exit 65
fi

entry="${desktop_entries[0]}"
if ! grep -q '^StartupWMClass=' "$entry"; then

  patched="$entry.appimagetool.tmp"
  in_desktop_entry=0
  inserted=0
  : > "$patched"
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "[Desktop Entry]")
        in_desktop_entry=1
        ;;
      "["*)
        if [[ $in_desktop_entry -eq 1 && $inserted -eq 0 ]]; then
          printf '%s\n' "$STARTUP_WM_CLASS" >> "$patched"
          inserted=1
        fi
        ;;
    esac
    printf '%s\n' "$line" >> "$patched"
  done < "$entry"
  if [[ $in_desktop_entry -eq 1 && $inserted -eq 0 ]]; then
    printf '%s\n' "$STARTUP_WM_CLASS" >> "$patched"
  fi
  mv -f -- "$patched" "$entry"
fi

canonical_entry="$app_dir/$DESKTOP_FILENAME"
if [[ "$entry" != "$canonical_entry" ]]; then
  mv -f -- "$entry" "$canonical_entry"
fi

exec "${APPIMAGETOOL_REAL:-/usr/local/bin/appimagetool.real}" "$@"
