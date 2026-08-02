from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path


APP_ID = "io.github.vincentzyuapps.dartflutterdemo"
FULL_VERSION_PATTERN = re.compile(
    r"^(?P<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)\+(?P<date>\d{8})$"
)
REPO_ROOT = Path(__file__).resolve().parents[4]
DEFAULT_TEMPLATE = (
    REPO_ROOT
    / "linux"
    / "packaging"
    / "flatpak"
    / f"{APP_ID}.metainfo.xml.in"
)
DEFAULT_OUTPUT = (
    REPO_ROOT / "build" / "flatpak" / "metadata" / f"{APP_ID}.metainfo.xml"
)


def read_pubspec_version(pubspec: Path) -> str:
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if line.startswith("version:"):
            version = line.partition(":")[2].strip()
            if version:
                return version
    raise ValueError(f"Missing version in {pubspec}")


def release_fields(full_version: str) -> tuple[str, str, str]:
    match = FULL_VERSION_PATTERN.fullmatch(full_version)
    if match is None:
        raise ValueError(
            "Flatpak metadata requires version X.Y.Z[-stage.N]+YYYYMMDD"
        )
    release_date = datetime.strptime(match.group("date"), "%Y%m%d").date()
    version = match.group("version")
    release_type = "development" if "-" in version else "stable"
    return version, release_date.isoformat(), release_type


def render_metadata(template: str, full_version: str) -> str:
    root = ET.fromstring(template)
    if root.findtext("id") != APP_ID:
        raise ValueError(f"MetaInfo app ID must be {APP_ID}")

    release = root.find("./releases/release")
    if release is None:
        raise ValueError("MetaInfo template must contain one release element")
    version, release_date, release_type = release_fields(full_version)
    release.set("version", version)
    release.set("date", release_date)
    release.set("type", release_type)

    ET.indent(root, space="  ")
    body = ET.tostring(root, encoding="unicode", short_empty_elements=True)
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + body + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render versioned AppStream metadata for the Flatpak bundle."
    )
    parser.add_argument("--pubspec", type=Path, default=REPO_ROOT / "pubspec.yaml")
    parser.add_argument("--template", type=Path, default=DEFAULT_TEMPLATE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    full_version = read_pubspec_version(args.pubspec)
    rendered = render_metadata(
        args.template.read_text(encoding="utf-8"), full_version
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Rendered {args.output} for {full_version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
