import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_ID = "io.github.vincentzyuapps.dartflutterdemo"
DEB_CONFIG = ROOT / "linux" / "packaging" / "deb" / "make_config.yaml"
WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"
SCRIPT = (
    ROOT / "scripts" / "ci" / "packaging" / "linux" / "patch-deb-desktop.py"
)

# Desktop entry exactly as flutter_app_packager 0.6.11 writes it into a deb: one
# flat [Desktop Entry] group and no action groups at all.
UNPATCHED_ENTRY = """[Desktop Entry]
Type=Application
Name=DartFlutterDemo
GenericName=DartFlutterDemo
Icon=dart_flutter_demo
Exec=dart_flutter_demo %U
Categories=Development;Utility;
Keywords=Dart;Flutter;Demo;
StartupNotify=true
"""

SPEC = importlib.util.spec_from_file_location("patch_deb_desktop", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class DebDesktopActionTests(unittest.TestCase):
    def test_patch_adds_the_seven_action_groups(self) -> None:
        patched = MODULE.patch_desktop_entry(UNPATCHED_ENTRY)

        MODULE.verify_desktop_entry(patched)
        self.assertIn(
            "Actions=System;Dialog;Type;Grid;Controls;About;Guide;", patched
        )
        self.assertIn(f"StartupWMClass={APP_ID}", patched)
        for label, name, argument in MODULE.DESKTOP_ACTIONS:
            self.assertIn(f"[Desktop Action {label}]", patched)
            self.assertIn(f"Name={name}", patched)
            self.assertIn(f"Exec=dart_flutter_demo {argument}", patched)

    def test_patch_is_idempotent(self) -> None:
        once = MODULE.patch_desktop_entry(UNPATCHED_ENTRY)

        self.assertEqual(MODULE.patch_desktop_entry(once), once)

    def test_patch_keeps_an_existing_window_class(self) -> None:
        configured = UNPATCHED_ENTRY.replace(
            "StartupNotify=true",
            f"StartupNotify=true\nStartupWMClass={APP_ID}",
        )

        patched = MODULE.patch_desktop_entry(configured)

        self.assertEqual(patched.count("StartupWMClass="), 1)

    def test_verifier_rejects_a_desktop_entry_without_actions(self) -> None:
        with self.assertRaises(SystemExit):
            MODULE.verify_desktop_entry(UNPATCHED_ENTRY)


class DebConfigurationTests(unittest.TestCase):
    def test_config_declares_the_window_class_but_no_actions(self) -> None:
        configured = DEB_CONFIG.read_text(encoding="utf-8")

        self.assertIn(f"startup_wm_class: {APP_ID}", configured)
        # The deb maker writes `Actions=` without the matching groups, which
        # leaves a dock menu empty, so the key has to stay out of the config.
        self.assertNotIn("actions:", configured)

    def test_release_workflow_patches_the_built_deb(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn(
            "python3 scripts/ci/packaging/linux/patch-deb-desktop.py", workflow
        )
        self.assertIn("-name '*.deb'", workflow)


if __name__ == "__main__":
    unittest.main()
