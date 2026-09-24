#!/usr/bin/env python3
"""Complete and verify the desktop entry inside a generated RPM package."""

from __future__ import annotations

import argparse
import importlib.util
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path


HERE = Path(__file__).resolve().parent
PATCHER_PATH = HERE / "patch-deb-desktop.py"
SPEC = importlib.util.spec_from_file_location("desktop_entry_patcher", PATCHER_PATH)
assert SPEC is not None and SPEC.loader is not None
PATCHER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = PATCHER
SPEC.loader.exec_module(PATCHER)

DESKTOP_GLOB = "usr/share/applications/*.desktop"


def _rpm_query(package: Path, query: str) -> str:
    return subprocess.check_output(
        ["rpm", "-qp", "--qf", query, str(package)], text=True
    ).strip()


def _unpack(package: Path, root: Path) -> None:
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


def _rpm_spec(root: Path, package: Path, topdir: Path) -> Path:
    metadata = {
        "name": _rpm_query(package, "%{NAME}"),
        "version": _rpm_query(package, "%{VERSION}"),
        "release": _rpm_query(package, "%{RELEASE}"),
        "arch": _rpm_query(package, "%{ARCH}"),
        "summary": _rpm_query(package, "%{SUMMARY}"),
        "license": _rpm_query(package, "%{LICENSE}"),
    }
    for key, value in metadata.items():
        if not value or "\n" in value or "%" in value:
            raise SystemExit(f"RPM metadata {key} is not safe to rebuild: {value!r}")

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
                f"Name: {metadata['name']}",
                f"Version: {metadata['version']}",
                f"Release: {metadata['release']}",
                f"Summary: {metadata['summary']}",
                f"License: {metadata['license']}",
                f"BuildArch: {metadata['arch']}",
                "Source0: payload.tar.gz",
                "",
                "%description",
                metadata["summary"],
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


def patch_rpm(package: Path) -> None:
    with tempfile.TemporaryDirectory() as workdir:
        work = Path(workdir)
        root = work / "package"
        _unpack(package, root)
        _desktop_entry(root, package)
        topdir = work / "rpmbuild"
        spec = _rpm_spec(root, package, topdir)
        subprocess.run(
            ["rpmbuild", "--define", f"_topdir {topdir}", "-bb", str(spec)],
            check=True,
        )
        rebuilt = next((topdir / "RPMS").rglob("*.rpm"), None)
        if rebuilt is None:
            raise SystemExit(f"rpmbuild did not produce an RPM for {package.name}")
        shutil.move(str(rebuilt), str(package))

    with tempfile.TemporaryDirectory() as workdir:
        root = Path(workdir) / "verify"
        _unpack(package, root)
        entries = sorted(root.glob(DESKTOP_GLOB))
        if len(entries) != 1 or entries[0].name != PATCHER.DESKTOP_FILENAME:
            raise SystemExit(f"{package.name} has no canonical desktop entry after rebuilding")
        PATCHER.verify_desktop_entry(entries[0].read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Expose the seven destinations as desktop entry actions of RPMs."
    )
    parser.add_argument("rpms", nargs="+", type=Path)
    args = parser.parse_args()
    for rpm in args.rpms:
        if not rpm.is_file():
            raise SystemExit(f"Missing RPM: {rpm}")
        patch_rpm(rpm.resolve())
        print(f"{rpm.name} declares the seven desktop actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
