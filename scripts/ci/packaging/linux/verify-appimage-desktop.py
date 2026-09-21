from __future__ import annotations

import argparse
import stat
import subprocess
import tempfile
from pathlib import Path


# Label, action name, and the argument the desktop shell has to forward.
EXPECTED_ACTIONS = (
    ("System", "System Info", "--tab=system"),
    ("Dialog", "Dialog Lab", "--tab=dialog"),
    ("Type", "Typography", "--tab=type"),
    ("Grid", "Adaptive Grid", "--tab=grid"),
    ("Controls", "Controls", "--tab=controls"),
    ("About", "About", "--action=about"),
    ("Guide", "Guide", "--action=guide"),
)

# Window class of the GTK window, see linux/runner/my_application.cc.
APP_ID = "io.github.vincentzyuapps.dartflutterdemo"


def parse_groups(text: str) -> dict[str, dict[str, str]]:
    groups: dict[str, dict[str, str]] = {}
    current: dict[str, str] | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = groups.setdefault(line[1:-1], {})
            continue
        if current is None or "=" not in line:
            continue
        key, _, value = line.partition("=")
        current[key.strip()] = value.strip()
    return groups


def extract_desktop_entry(appimage: Path) -> str:
    appimage.chmod(appimage.stat().st_mode | stat.S_IXUSR)
    with tempfile.TemporaryDirectory() as workdir:
        root = Path(workdir)
        subprocess.run(
            [str(appimage), "--appimage-extract"],
            cwd=root,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        appdir = root / "squashfs-root"
        entries = sorted(appdir.glob("*.desktop"))
        if len(entries) != 1:
            raise SystemExit(
                f"Expected exactly one desktop entry in {appdir}, found {len(entries)}"
            )
        return entries[0].read_text(encoding="utf-8")


def verify_desktop_entry(text: str) -> None:
    groups = parse_groups(text)
    main = groups.get("Desktop Entry")
    if main is None:
        raise SystemExit("The desktop entry has no [Desktop Entry] group")

    declared = [name for name in main.get("Actions", "").split(";") if name]
    expected = [label for label, _, _ in EXPECTED_ACTIONS]
    if declared != expected:
        raise SystemExit(f"Expected Actions={';'.join(expected)};, found {declared}")

    # The dock matches the running window with the launcher through this key, so
    # losing it would silently add a second, unnamed dock entry.
    if main.get("StartupWMClass") != APP_ID:
        raise SystemExit(f"Expected StartupWMClass={APP_ID}")

    for label, name, argument in EXPECTED_ACTIONS:
        action = groups.get(f"Desktop Action {label}")
        if action is None:
            raise SystemExit(f"Missing [Desktop Action {label}] group")
        if action.get("Name") != name:
            raise SystemExit(
                f"Desktop Action {label} is named {action.get('Name')!r}, not {name!r}"
            )
        if argument not in action.get("Exec", ""):
            raise SystemExit(
                f"Desktop Action {label} does not run {argument}: {action.get('Exec')!r}"
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Verify that a built AppImage exposes the seven application "
            "destinations as desktop entry actions."
        )
    )
    parser.add_argument("appimage", type=Path)
    args = parser.parse_args()

    appimage = args.appimage.resolve()
    if not appimage.is_file():
        raise SystemExit(f"Missing AppImage: {appimage}")

    verify_desktop_entry(extract_desktop_entry(appimage))
    print(f"{appimage.name} declares the seven desktop actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
