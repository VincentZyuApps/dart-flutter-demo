from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
DEFAULT_PUBSPEC = ROOT / "pubspec.yaml"
DEFAULT_ICON = ROOT / "assets" / "images" / "logo-icon-favicon.png"
EXECUTABLE_NAME = "dart_flutter_demo.exe"

MSIX_NS = "http://schemas.microsoft.com/appx/manifest/foundation/windows10"
UAP_NS = "http://schemas.microsoft.com/appx/manifest/uap/windows10"
RESCAP_NS = "http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"

ET.register_namespace("", MSIX_NS)
ET.register_namespace("uap", UAP_NS)
ET.register_namespace("rescap", RESCAP_NS)

VERSION_PATTERN = re.compile(
    r"^(?P<base>\d+\.\d+\.\d+)"
    r"(?:-(?P<stage>alpha|beta|rc)\.(?P<sequence>\d+))?"
    r"\+(?P<date>\d{8})$"
)
STAGE_BASE = {
    "alpha": 10000,
    "beta": 20000,
    "rc": 30000,
    "stable": 60000,
}


def read_pubspec_version(path: Path) -> str:
    matches = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"version:\s*(\S+)\s*", line)
        if match:
            matches.append(match.group(1))
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one version field in {path}")
    return matches[0]


def store_version_from_pubspec(full_version: str) -> str:
    match = VERSION_PATTERN.fullmatch(full_version)
    if match is None:
        raise ValueError(
            "Version must use X.Y.Z[-alpha|beta|rc.N]+YYYYMMDD: "
            f"{full_version}"
        )

    build_date = dt.datetime.strptime(match.group("date"), "%Y%m%d").date()
    stage = match.group("stage") or "stable"
    sequence_text = match.group("sequence")
    sequence = int(sequence_text) if sequence_text is not None else 0
    if stage != "stable" and sequence < 1:
        raise ValueError("Prerelease sequence must be at least 1")

    stage_and_sequence = STAGE_BASE[stage] + sequence
    if stage_and_sequence > 65535:
        raise ValueError("Store stage and sequence field exceeds 65535")

    month_day = int(build_date.strftime("%m%d"))
    return f"{build_date.year}.{month_day}.{stage_and_sequence}.0"


def validate_release_metadata(
    metadata: dict[str, object],
    package_path: Path,
    *,
    full_version: str,
    identity_name: str,
    publisher: str,
    publisher_display_name: str,
    display_name: str,
) -> None:
    expected = {
        "application_version": full_version.split("+", maxsplit=1)[0],
        "pubspec_version": full_version,
        "store_version": store_version_from_pubspec(full_version),
        "architecture": "x64",
        "identity_name": identity_name,
        "publisher": publisher,
        "publisher_display_name": publisher_display_name,
        "display_name": display_name,
        "signed": False,
        "filename": package_path.name,
        "size_bytes": package_path.stat().st_size,
        "sha256": sha256_file(package_path),
    }
    for field, expected_value in expected.items():
        actual_value = metadata.get(field)
        if actual_value != expected_value:
            raise ValueError(
                f"Store package metadata mismatch for {field}: "
                f"expected {expected_value!r}, got {actual_value!r}"
            )


def render_manifest(
    *,
    store_version: str,
    identity_name: str,
    publisher: str,
    publisher_display_name: str,
    display_name: str,
) -> bytes:
    def q(namespace: str, name: str) -> str:
        return f"{{{namespace}}}{name}"

    package = ET.Element(
        q(MSIX_NS, "Package"), {"IgnorableNamespaces": "uap rescap"}
    )
    ET.SubElement(
        package,
        q(MSIX_NS, "Identity"),
        {
            "Name": identity_name,
            "Publisher": publisher,
            "Version": store_version,
            "ProcessorArchitecture": "x64",
        },
    )

    properties = ET.SubElement(package, q(MSIX_NS, "Properties"))
    ET.SubElement(properties, q(MSIX_NS, "DisplayName")).text = display_name
    ET.SubElement(properties, q(MSIX_NS, "PublisherDisplayName")).text = (
        publisher_display_name
    )
    ET.SubElement(properties, q(MSIX_NS, "Logo")).text = "Assets\\StoreLogo.png"

    resources = ET.SubElement(package, q(MSIX_NS, "Resources"))
    ET.SubElement(resources, q(MSIX_NS, "Resource"), {"Language": "en-us"})
    ET.SubElement(resources, q(MSIX_NS, "Resource"), {"Language": "zh-cn"})

    dependencies = ET.SubElement(package, q(MSIX_NS, "Dependencies"))
    ET.SubElement(
        dependencies,
        q(MSIX_NS, "TargetDeviceFamily"),
        {
            "Name": "Windows.Desktop",
            "MinVersion": "10.0.17763.0",
            "MaxVersionTested": "10.0.26100.0",
        },
    )

    applications = ET.SubElement(package, q(MSIX_NS, "Applications"))
    application = ET.SubElement(
        applications,
        q(MSIX_NS, "Application"),
        {
            "Id": "DartFlutterDemo",
            "Executable": EXECUTABLE_NAME,
            "EntryPoint": "Windows.FullTrustApplication",
        },
    )
    ET.SubElement(
        application,
        q(UAP_NS, "VisualElements"),
        {
            "DisplayName": display_name,
            "Description": "Cross-platform Flutter UI showcase",
            "BackgroundColor": "transparent",
            "Square150x150Logo": "Assets\\Square150x150Logo.png",
            "Square44x44Logo": "Assets\\Square44x44Logo.png",
        },
    )

    capabilities = ET.SubElement(package, q(MSIX_NS, "Capabilities"))
    ET.SubElement(capabilities, q(RESCAP_NS, "Capability"), {"Name": "runFullTrust"})

    ET.indent(package, space="  ")
    return ET.tostring(package, encoding="utf-8", xml_declaration=True)


def generate_msix_assets(source: Path, assets_dir: Path) -> None:
    try:
        from PIL import Image
    except ModuleNotFoundError as exc:  # pragma: no cover - exercised in CI
        raise RuntimeError(
            "Pillow is required to generate MSIX assets. "
            "Install the pinned CI dependency first."
        ) from exc

    assets_dir.mkdir(parents=True, exist_ok=True)
    image = Image.open(source).convert("RGBA")
    sizes = {
        "StoreLogo.png": 50,
        "Square44x44Logo.png": 44,
        "Square150x150Logo.png": 150,
    }
    for filename, size in sizes.items():
        resized = image.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(assets_dir / filename, format="PNG", optimize=True)


def find_makeappx(explicit_path: Path | None = None) -> Path:
    if explicit_path is not None:
        candidate = explicit_path.resolve()
        if not candidate.is_file():
            raise FileNotFoundError(f"MakeAppx.exe not found: {candidate}")
        return candidate

    on_path = shutil.which("makeappx.exe") or shutil.which("makeappx")
    if on_path:
        return Path(on_path).resolve()

    program_files = os.environ.get("ProgramFiles(x86)")
    if program_files:
        sdk_bin = Path(program_files) / "Windows Kits" / "10" / "bin"
        candidates = list(sdk_bin.glob("*/x64/MakeAppx.exe"))
        candidates.extend(sdk_bin.glob("*/x64/makeappx.exe"))
        if candidates:
            return max(candidates, key=windows_sdk_version)

    raise FileNotFoundError("MakeAppx.exe was not found in PATH or Windows Kits")


def windows_sdk_version(path: Path) -> tuple[int, ...]:
    version = path.parents[1].name
    if not re.fullmatch(r"\d+(?:\.\d+)*", version):
        return ()
    return tuple(int(part) for part in version.split("."))


def validate_bundle(bundle: Path) -> None:
    required = [
        bundle / EXECUTABLE_NAME,
        bundle / "flutter_windows.dll",
        bundle / "data",
        bundle / "data" / "flutter_assets",
    ]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise FileNotFoundError("Windows release bundle is incomplete: " + ", ".join(missing))


def validate_msix(
    package_path: Path,
    *,
    identity_name: str,
    publisher: str,
    store_version: str,
) -> None:
    required_entries = {
        "AppxManifest.xml",
        "AppxBlockMap.xml",
        "[Content_Types].xml",
        EXECUTABLE_NAME,
        "flutter_windows.dll",
        "Assets/StoreLogo.png",
        "Assets/Square44x44Logo.png",
        "Assets/Square150x150Logo.png",
    }
    with zipfile.ZipFile(package_path) as archive:
        bad_entry = archive.testzip()
        if bad_entry is not None:
            raise ValueError(f"Corrupt MSIX entry: {bad_entry}")
        names = set(archive.namelist())
        missing = sorted(required_entries - names)
        if missing:
            raise ValueError(f"MSIX is missing entries: {', '.join(missing)}")
        manifest = ET.fromstring(archive.read("AppxManifest.xml"))

    identity = manifest.find(f"{{{MSIX_NS}}}Identity")
    if identity is None:
        raise ValueError("MSIX manifest has no Identity element")
    expected = {
        "Name": identity_name,
        "Publisher": publisher,
        "Version": store_version,
        "ProcessorArchitecture": "x64",
    }
    actual = {name: identity.get(name) for name in expected}
    if actual != expected:
        raise ValueError(f"MSIX identity mismatch: expected {expected}, got {actual}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_msix(args: argparse.Namespace) -> dict[str, object]:
    bundle = args.bundle.resolve()
    output = args.output.resolve()
    icon = args.icon.resolve()
    pubspec = args.pubspec.resolve()
    validate_bundle(bundle)
    if not icon.is_file():
        raise FileNotFoundError(f"Source icon not found: {icon}")

    full_version = read_pubspec_version(pubspec)
    store_version = store_version_from_pubspec(full_version)
    makeappx = find_makeappx(args.makeappx)
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="dart-flutter-demo-msix-") as temp:
        temp_root = Path(temp)
        staging = temp_root / "staging"
        verification = temp_root / "verification"
        shutil.copytree(bundle, staging)
        (staging / "AppxManifest.xml").write_bytes(
            render_manifest(
                store_version=store_version,
                identity_name=args.identity_name,
                publisher=args.publisher,
                publisher_display_name=args.publisher_display_name,
                display_name=args.display_name,
            )
        )
        generate_msix_assets(icon, staging / "Assets")

        subprocess.run(
            [
                str(makeappx),
                "pack",
                "/d",
                str(staging),
                "/p",
                str(output),
                "/o",
            ],
            check=True,
        )
        validate_msix(
            output,
            identity_name=args.identity_name,
            publisher=args.publisher,
            store_version=store_version,
        )
        subprocess.run(
            [
                str(makeappx),
                "unpack",
                "/p",
                str(output),
                "/d",
                str(verification),
                "/o",
            ],
            check=True,
        )
        if not (verification / EXECUTABLE_NAME).is_file():
            raise ValueError("MakeAppx unpack verification did not restore the executable")

    metadata = {
        "application_version": full_version.split("+", maxsplit=1)[0],
        "pubspec_version": full_version,
        "store_version": store_version,
        "architecture": "x64",
        "identity_name": args.identity_name,
        "publisher": args.publisher,
        "publisher_display_name": args.publisher_display_name,
        "display_name": args.display_name,
        "signed": False,
        "filename": output.name,
        "size_bytes": output.stat().st_size,
        "sha256": sha256_file(output),
    }
    metadata_path = output.with_suffix(output.suffix + ".json")
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=True, indent=2) + "\n", encoding="utf-8"
    )
    return metadata


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build or validate an unsigned Windows x64 Store MSIX."
    )
    parser.add_argument("--bundle", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--metadata",
        type=Path,
        help="Validate an existing MSIX against this metadata JSON instead of building.",
    )
    parser.add_argument("--pubspec", type=Path, default=DEFAULT_PUBSPEC)
    parser.add_argument("--icon", type=Path, default=DEFAULT_ICON)
    parser.add_argument("--identity-name", required=True)
    parser.add_argument("--publisher", required=True)
    parser.add_argument("--publisher-display-name", required=True)
    parser.add_argument("--display-name", required=True)
    parser.add_argument("--makeappx", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.metadata is not None:
        metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
        validate_release_metadata(
            metadata,
            args.output,
            full_version=read_pubspec_version(args.pubspec),
            identity_name=args.identity_name,
            publisher=args.publisher,
            publisher_display_name=args.publisher_display_name,
            display_name=args.display_name,
        )
    else:
        if args.bundle is None:
            raise ValueError("--bundle is required when building an MSIX")
        metadata = build_msix(args)
    print(json.dumps(metadata, ensure_ascii=True, indent=2))


if __name__ == "__main__":
    main()
