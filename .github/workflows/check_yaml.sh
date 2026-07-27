#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  files=(
    "$SCRIPT_DIR/build-release.yml"
    "$SCRIPT_DIR/profile-debug.yml"
    "$SCRIPT_DIR/performance.yml"
    "$SCRIPT_DIR/platform-bootstrap.yml"
  )
fi

for file in "${files[@]}"; do
  if [[ ! -f "$file" && -f "$SCRIPT_DIR/$file" ]]; then
    file="$SCRIPT_DIR/$file"
  fi
  if [[ ! -f "$file" ]]; then
    echo "File not found: $file" >&2
    exit 1
  fi
  echo "Checking $file"
  yamllint -d relaxed "$file"
done

echo "All workflow YAML files passed yamllint."
