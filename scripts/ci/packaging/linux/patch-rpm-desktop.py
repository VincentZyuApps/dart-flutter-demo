#!/usr/bin/env python3
"""Build and verify an RPM from an already validated Debian payload."""

from __future__ import annotations

import argparse
import importlib.util
import shutil
import subprocess
import sys
import tarfile
import tempfile
import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
PATCHER_PATH = HERE / "patch-deb-desktop.py"
SPEC = importlib.util.spec_from_file_location("desktop_entry_patcher", PATCHER_PATH)
assert SPEC is not None and SPEC.loader is not None
PATCHER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = PATCHER
SPEC.loader.exec_module(PATCHER)

DESKTOP_GLOB = "usr/share/applications/*.desktop"
LAUNCHER_PATH = Path("usr/bin/dart_flutter_demo")
PAYLOAD_EXECUTABLE_PATH = Path("opt/dart_flutter_demo/dart_flutter_demo")


PACKAGE_NAME = "dart-flutter-demo-showcase"
SUMMARY = "Explore Flutter controls and cross-platform system information"
LICENSE = "MIT"
VERSION_PATTERN = re.compile(
    r"(?P<version>\d+\.\d+\.\d+)(?:-(?P<stage>alpha|beta|rc)\.(?P<sequence>[1-9]\d*))?"
    r"(?:\+(?P<date>\d{8}))?$"
)


def _unpack_rpm(package: Path, root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    command = f'rpm2cpio "{package}" | cpio -idm --quiet -D "{root}"'
    subprocess.run(["bash", "-c", command], check=True)


def _desktop_entry(root: Path, package: Path) -> Path:
    entries = sorted(root.glob(DESKTOP_GLOB))
    if len(entries) != 1:
        raise SystemExit(
            f"Expected exactly one desktop entry in {package.name}, found {len(entries)}"
        )
    entry = entries[0]
    canonical = entry.with_name(PATCHER.DESKTOP_FILENAME)
    entry.write_text(
        PATCHER.patch_desktop_entry(entry.read_text(encoding="utf-8")),
        encoding="utf-8",
    )
    if entry != canonical:
        entry.rename(canonical)
    return canonical


def _install_launcher(root: Path) -> Path:
    """Adds the command used by the RPM desktop entry and its actions.

    flutter_app_packager places the Linux bundle in ``/opt/dart_flutter_demo``.
    Its generated desktop entry invokes ``dart_flutter_demo`` by name, but the
    rebuilt RPM has no PATH-visible executable unless we add one ourselves.
    Keep the desktop entry portable and provide the conventional /usr/bin
    launcher instead of embedding an RPM-specific absolute path in every
    action.
    """
    payload = root / PAYLOAD_EXECUTABLE_PATH
    if not payload.is_file():
        raise SystemExit(f"RPM payload has no executable at {payload}")

    launcher = root / LAUNCHER_PATH
    launcher.parent.mkdir(parents=True, exist_ok=True)
    launcher.write_text(
        "#!/bin/sh\nexec /opt/dart_flutter_demo/dart_flutter_demo \"$@\"\n",
        encoding="utf-8",
        newline="\n",
    )
    launcher.chmod(0o755)
    return launcher


def _verify_launcher(root: Path, package: Path) -> None:
    launcher = root / LAUNCHER_PATH
    if not launcher.is_file() or not launcher.stat().st_mode & 0o111:
        raise SystemExit(f"{package.name} has no executable {LAUNCHER_PATH}")
    expected = "exec /opt/dart_flutter_demo/dart_flutter_demo \"$@\""
    if expected not in launcher.read_text(encoding="utf-8"):
        raise SystemExit(f"{package.name} launcher does not start the bundled executable")


def rpm_fields(full_version: str) -> tuple[str, str]:
    match = VERSION_PATTERN.fullmatch(full_version)
    if match is None:
        raise ValueError(
            "RPM package metadata requires X.Y.Z[-alpha.N|-beta.N|-rc.N][+YYYYMMDD]"
        )
    date_suffix = f".{match.group('date')}" if match.group("date") else ""
    stage = match.group("stage")
    if stage is None:
        return match.group("version"), f"1{date_suffix}"
    return (
        match.group("version"),
        f"0.{stage}.{match.group('sequence')}{date_suffix}",
    )


def _rpm_spec(root: Path, topdir: Path, version: str, release: str, arch: str) -> Path:

    source = topdir / "SOURCES" / "payload.tar.gz"
    source.parent.mkdir(parents=True)
    with tarfile.open(source, "w:gz") as archive:
        for item in root.iterdir():
            archive.add(item, arcname=item.name, recursive=True)

    files: list[str] = []
    for entry in sorted(root.rglob("*")):
        relative = "/" + entry.relative_to(root).as_posix()
        files.append(f"%dir {relative}" if entry.is_dir() else relative)
    spec = topdir / "SPECS" / "patched.spec"
    spec.parent.mkdir(parents=True)
    spec.write_text(
        "\n".join(
            [
                "%global debug_package %{nil}",
                f"Name: {PACKAGE_NAME}",
                f"Version: {version}",
                f"Release: {release}",
                f"Summary: {SUMMARY}",
                f"License: {LICENSE}",
                f"BuildArch: {arch}",
                "Source0: payload.tar.gz",
                "",
                "%description",
                SUMMARY,
                "",
                "%prep",
                "%setup -q -c -T",
                "tar -xzf %{_sourcedir}/payload.tar.gz",
                "",
                "%build",
                "",
                "%install",
                "mkdir -p %{buildroot}",
                "cp -a . %{buildroot}/",
                "",
                "%files",
                "%defattr(-,root,root,-)",
                *files,
                "",
            ]
        ),
        encoding="utf-8",
    )
    return spec


def build_rpm(deb: Path, full_version: str) -> Path:
    rpm_version, rpm_release = rpm_fields(full_version)
    with tempfile.TemporaryDirectory() as workdir:
        work = Path(workdir)
        root = work / "package"
        subprocess.run(["dpkg-deb", "-x", str(deb), str(root)], check=True)
        _desktop_entry(root, deb)
        _install_launcher(root)
        topdir = work / "rpmbuild"
        spec = _rpm_spec(root, topdir, rpm_version, rpm_release, "x86_64")
        subprocess.run(
            ["rpmbuild", "--define", f"_topdir {topdir}", "-bb", str(spec)],
            check=True,
        )
        rebuilt = next((topdir / "RPMS").rglob("*.rpm"), None)
        if rebuilt is None:
            raise SystemExit(f"rpmbuild did not produce an RPM for {deb.name}")
        package = deb.with_name(
            f"{PACKAGE_NAME}-{rpm_version}-{rpm_release}.x86_64.rpm"
        )
        shutil.move(str(rebuilt), str(package))

    with tempfile.TemporaryDirectory() as workdir:
        root = Path(workdir) / "verify"
        _unpack_rpm(package, root)
        entries = sorted(root.glob(DESKTOP_GLOB))
        if len(entries) != 1 or entries[0].name != PATCHER.DESKTOP_FILENAME:
            raise SystemExit(f"{package.name} has no canonical desktop entry after rebuilding")
        PATCHER.verify_desktop_entry(entries[0].read_text(encoding="utf-8"))
        _verify_launcher(root, package)
    return package


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build RPMs with the seven desktop actions from validated Debian payloads."
    )
    parser.add_argument("--version", required=True)
    parser.add_argument("debs", nargs="+", type=Path)
    args = parser.parse_args()
    for deb in args.debs:
        if not deb.is_file():
            raise SystemExit(f"Missing Debian package: {deb}")
        package = build_rpm(deb.resolve(), args.version)
        print(f"{package.name} declares the seven desktop actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
