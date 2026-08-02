#!/usr/bin/env bash

set -euo pipefail

BUNDLE="${1:?Flatpak bundle path is required}"
EXPECTED_VERSION="${2:?Expected application version is required}"
APP_ID="${FLATPAK_APP_ID:-io.github.vincentzyuapps.dartflutterdemo}"

test -s "$BUNDLE"
flatpak install --user --noninteractive "$BUNDLE"
flatpak info --user "$APP_ID" > flatpak-info.txt
flatpak info --user --show-permissions "$APP_ID" > flatpak-permissions.txt
flatpak run --user --command=cat "$APP_ID" \
  "/app/share/metainfo/${APP_ID}.metainfo.xml" > installed-metainfo.xml

REF="$(flatpak info --user --show-ref "$APP_ID")"
test "$REF" = "app/${APP_ID}/x86_64/stable"

if ! grep -Fq "<release version=\"$EXPECTED_VERSION\"" installed-metainfo.xml; then
  echo "Expected Flatpak release version was not installed." >&2
  cat installed-metainfo.xml >&2
  exit 1
fi

if grep -Eq 'filesystems=(host|home)|devices=all|system-bus|session-bus' \
  flatpak-permissions.txt; then
  echo "Unexpected broad Flatpak permission detected." >&2
  cat flatpak-permissions.txt >&2
  exit 1
fi

flatpak run --user --command=sh "$APP_ID" -c \
  'test -x /app/lib/dart-flutter-demo/dart_flutter_demo'

set +e
timeout --signal=TERM --kill-after=5s 20s \
  dbus-run-session -- xvfb-run -a \
  flatpak run --user \
    --env=LIBGL_ALWAYS_SOFTWARE=1 \
    --env=NO_AT_BRIDGE=1 \
    "$APP_ID" > flatpak-smoke.log 2>&1
STATUS=$?
set -e

if [[ "$STATUS" -ne 124 ]]; then
  echo "Flatpak exited before the 20-second smoke window (status $STATUS)." >&2
  cat flatpak-smoke.log >&2
  exit 1
fi
