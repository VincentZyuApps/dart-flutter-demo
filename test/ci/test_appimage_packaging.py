import importlib.util
import re
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_ID = "io.github.vincentzyuapps.dartflutterdemo"
APPIMAGE_CONFIG = (
    ROOT / "linux" / "packaging" / "appimage" / "make_config.yaml"
)
FLATPAK_DESKTOP = (
    ROOT / "linux" / "packaging" / "flatpak" / f"{APP_ID}.desktop"
)
WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"
VERIFIER = (
    ROOT
    / "scripts"
    / "ci"
    / "packaging"
    / "linux"
    / "verify-appimage-desktop.py"
)
APPIMAGE_ACTION_PATTERN = re.compile(
    r"^  - label: (?P<label>\S+)\n"
    r"    name: (?P<name>.+)\n"
    r"    arguments:\n"
    r"      - (?P<argument>\S+)$",
    re.MULTILINE,
)

SPEC = importlib.util.spec_from_file_location("verify_appimage_desktop", VERIFIER)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class AppImageDesktopTests(unittest.TestCase):
    def test_config_declares_the_seven_destinations(self) -> None:
        text = APPIMAGE_CONFIG.read_text(encoding="utf-8")
        declared = [
            (match["label"], match["name"], match["argument"])
            for match in APPIMAGE_ACTION_PATTERN.finditer(text)
        ]
        self.assertEqual(
            declared,
            [
                ("System", "System Info", "--tab=system"),
                ("Dialog", "Dialog Lab", "--tab=dialog"),
                ("Type", "Typography", "--tab=type"),
                ("Grid", "Adaptive Grid", "--tab=grid"),
                ("Controls", "Controls", "--tab=controls"),
                ("About", "About", "--action=about"),
                ("Guide", "Guide", "--action=guide"),
            ],
        )

    def test_flatpak_desktop_entry_exposes_the_same_destinations(self) -> None:
        text = FLATPAK_DESKTOP.read_text(encoding="utf-8")
        declared = re.findall(r"^Actions=(.*)$", text, re.MULTILINE)
        self.assertEqual(len(declared), 1)
        labels = [label for label in declared[0].split(";") if label]

        names: list[str] = []
        arguments: list[str] = []
        for label in labels:
            group = text.split(f"[Desktop Action {label}]", 1)[1]
            group = group.split("\n\n", 1)[0]
            entries = dict(
                line.split("=", 1)
                for line in group.splitlines()
                if "=" in line
            )
            names.append(entries["Name"])
            arguments.append(entries["Exec"].split(" ", 1)[1])

        configured = [
            (match["label"], match["name"], match["argument"])
            for match in APPIMAGE_ACTION_PATTERN.finditer(
                APPIMAGE_CONFIG.read_text(encoding="utf-8")
            )
        ]
        self.assertEqual(
            configured,
            list(zip(labels, names, arguments, strict=True)),
        )

    def test_verifier_expectations_match_the_config(self) -> None:
        configured = [
            (match["label"], match["name"], match["argument"])
            for match in APPIMAGE_ACTION_PATTERN.finditer(
                APPIMAGE_CONFIG.read_text(encoding="utf-8")
            )
        ]
        self.assertEqual(list(MODULE.EXPECTED_ACTIONS), configured)

    def test_release_workflow_verifies_the_built_appimage(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn(
            "python3 scripts/ci/packaging/linux/verify-appimage-desktop.py",
            workflow,
        )
        self.assertIn("-name '*.AppImage'", workflow)

        verifier = VERIFIER.read_text(encoding="utf-8")
        self.assertIn("--appimage-extract", verifier)
        self.assertIn("squashfs-root", verifier)

    def test_verifier_checks_the_window_class(self) -> None:
        verifier = VERIFIER.read_text(encoding="utf-8")
        wrapper = (
            ROOT
            / "scripts"
            / "ci"
            / "packaging"
            / "linux"
            / "appimagetool-wrapper.sh"
        ).read_text(encoding="utf-8")

        self.assertEqual(MODULE.APP_ID, APP_ID)
        self.assertIn("StartupWMClass", verifier)
        self.assertIn(f"StartupWMClass={APP_ID}", wrapper)


if __name__ == "__main__":
    unittest.main()
