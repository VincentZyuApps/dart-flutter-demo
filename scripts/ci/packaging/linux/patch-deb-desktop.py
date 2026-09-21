#!/usr/bin/env python3
"""Adds the seven destination actions to a packaged deb.

The deb maker of flutter_app_packager writes every desktop entry key into a
single `[Desktop Entry]` group, and it never emits the `[Desktop Action ...]`
groups that `Actions=` refers to. Windows and the AppImage already expose the
seven destinations, so the built package is unpacked here, completed, and packed
again before it is uploaded.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path


# Action name, label, and the argument the desktop shell has to forward.
DESKTOP_ACTIONS = (
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

DESKTOP_GLOB = "usr/share/applications/*.desktop"


def parse_groups(text: str) -> tuple[list[str], dict[str, dict[str, str]]]:
    """Splits a desktop entry into its groups, keeping the original order."""
    order: list[str] = []
    groups: dict[str, dict[str, str]] = {}
    current: dict[str, str] | None = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            name = line[1:-1]
            current = groups.setdefault(name, {})
            if name not in order:
                order.append(name)
            continue
        if current is None or "=" not in line:
            continue
        key, _, value = line.partition("=")
        current[key.strip()] = value.strip()
    return order, groups


def render_groups(order: list[str], groups: dict[str, dict[str, str]]) -> str:
    lines: list[str] = []
    for name in order:
        if lines:
            lines.append("")
        lines.append(f"[{name}]")
        for key, value in groups[name].items():
            lines.append(f"{key}={value}")
    return "\n".join(lines) + "\n"


def exec_command(exec_line: str) -> str:
    """Drops the field codes, which only make sense for the main entry."""
    tokens = [token for token in exec_line.split() if not token.startswith("%")]
    if not tokens:
        raise SystemExit("The desktop entry has no Exec command.")
    return " ".join(tokens)


def patch_desktop_entry(text: str) -> str:
    order, groups = parse_groups(text)
    main = groups.get("Desktop Entry")
    if main is None:
        raise SystemExit("The desktop entry has no [Desktop Entry] group.")

    labels = [label for label, _, _ in DESKTOP_ACTIONS]
    main["Actions"] = ";".join(labels) + ";"
    main.setdefault("StartupWMClass", APP_ID)

    command = exec_command(main.get("Exec", ""))
    for label, name, argument in DESKTOP_ACTIONS:
        group = f"Desktop Action {label}"
        groups[group] = {"Name": name, "Exec": f"{command} {argument}"}
        if group not in order:
            order.append(group)
    return render_groups(order, groups)


def verify_desktop_entry(text: str) -> None:
    groups = parse_groups(text)[1]
    main = groups.get("Desktop Entry")
    if main is None:
        raise SystemExit("The patched desktop entry lost its [Desktop Entry].")

    declared = [name for name in main.get("Actions", "").split(";") if name]
    expected = [label for label, _, _ in DESKTOP_ACTIONS]
    if declared != expected:
        raise SystemExit(f"Expected Actions={';'.join(expected)};, found {declared}")
    if main.get("StartupWMClass") != APP_ID:
        raise SystemExit(f"Expected StartupWMClass={APP_ID}")

    for label, name, argument in DESKTOP_ACTIONS:
        action = groups.get(f"Desktop Action {label}")
        if action is None:
            raise SystemExit(f"Missing [Desktop Action {label}] group.")
        if action.get("Name") != name:
            raise SystemExit(
                f"Desktop Action {label} is named {action.get('Name')!r}, not {name!r}."
            )
        if argument not in action.get("Exec", ""):
            raise SystemExit(
                f"Desktop Action {label} does not run {argument}: {action.get('Exec')!r}"
            )


def patch_deb(deb: Path) -> None:
    with tempfile.TemporaryDirectory() as workdir:
        root = Path(workdir) / "package"
        subprocess.run(["dpkg-deb", "-R", str(deb), str(root)], check=True)

        entries = sorted(root.glob(DESKTOP_GLOB))
        if len(entries) != 1:
            raise SystemExit(
                f"Expected exactly one desktop entry in {deb.name}, found {len(entries)}"
            )
        entry = entries[0]
        entry.write_text(
            patch_desktop_entry(entry.read_text(encoding="utf-8")),
            encoding="utf-8",
        )

        patched = Path(workdir) / deb.name
        subprocess.run(
            ["dpkg-deb", "-b", "--root-owner-group", str(root), str(patched)],
            check=True,
        )
        shutil.move(str(patched), str(deb))

    # Prove that the repacked file carries the actions; a silent regression here
    # is exactly what makes a dock menu look empty.
    with tempfile.TemporaryDirectory() as workdir:
        root = Path(workdir) / "verify"
        subprocess.run(["dpkg-deb", "-R", str(deb), str(root)], check=True)
        entries = sorted(root.glob(DESKTOP_GLOB))
        if len(entries) != 1:
            raise SystemExit(f"Expected one desktop entry in {deb.name} after patching.")
        verify_desktop_entry(entries[0].read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Expose the seven destinations as desktop entry actions of a deb."
    )
    parser.add_argument("debs", nargs="+", type=Path)
    args = parser.parse_args()

    for deb in args.debs:
        if not deb.is_file():
            raise SystemExit(f"Missing deb: {deb}")
        patch_deb(deb.resolve())
        print(f"{deb.name} declares the seven desktop actions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
