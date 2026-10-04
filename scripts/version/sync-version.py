#!/usr/bin/env python3
"""Synchronize application version from pubspec.yaml to lib/application_version.dart."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
PUBSPEC_PATH = REPO_ROOT / "pubspec.yaml"
DART_VERSION_PATH = REPO_ROOT / "lib" / "application_version.dart"


def get_pubspec_version(pubspec_path: Path = PUBSPEC_PATH) -> str:
    content = pubspec_path.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([^\s]+)", content, re.MULTILINE)
    if not match:
        raise ValueError(f"Could not find version entry in {pubspec_path}")
    return match.group(1).strip()


def sync_version(
    pubspec_path: Path = PUBSPEC_PATH,
    dart_path: Path = DART_VERSION_PATH,
    check_only: bool = False,
) -> bool:
    target_version = get_pubspec_version(pubspec_path)
    dart_content = dart_path.read_text(encoding="utf-8")
    pattern = r"(const\s+String\s+applicationVersion\s*=\s*')[^']+(';)"

    match = re.search(pattern, dart_content)
    if not match:
        raise ValueError(f"Could not find applicationVersion constant in {dart_path}")

    current_version = match.group(0).split("'")[1]

    if check_only:
        if current_version != target_version:
            print(
                f"[MISMATCH] Version in {dart_path.name} ('{current_version}') "
                f"does not match {pubspec_path.name} ('{target_version}').",
                file=sys.stderr,
            )
            return False
        print(f"[OK] Application version matches pubspec: {target_version}")
        return True

    if current_version == target_version:
        print(f"[UP-TO-DATE] {dart_path.name} is already at version: {target_version}")
        return True

    new_content = re.sub(pattern, rf"\g<1>{target_version}\g<2>", dart_content)
    dart_path.write_text(new_content, encoding="utf-8")
    print(f"[SYNCED] Updated {dart_path.name}: {current_version} -> {target_version}")
    return True


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Synchronize application version from pubspec.yaml to lib/application_version.dart"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check whether application_version.dart matches pubspec.yaml without modifying files",
    )
    args = parser.parse_args()

    success = sync_version(check_only=args.check)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
