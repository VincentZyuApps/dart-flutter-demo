import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RPM_CONFIG = ROOT / "linux" / "packaging" / "rpm" / "make_config.yaml"
WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"
SCRIPT = ROOT / "scripts" / "ci" / "packaging" / "linux" / "patch-rpm-desktop.py"

SPEC = importlib.util.spec_from_file_location("patch_rpm_desktop", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class RpmPackagingTests(unittest.TestCase):
    def test_config_keeps_packager_metadata(self) -> None:
        content = RPM_CONFIG.read_text(encoding="utf-8")
        self.assertIn("packager: VincentZyu", content)
        self.assertIn("group: Applications/Development", content)

    def test_rebuild_uses_the_same_desktop_action_contract_as_deb(self) -> None:
        self.assertEqual(MODULE.PATCHER.DESKTOP_FILENAME,
                         "io.github.vincentzyuapps.dartflutterdemo.desktop")
        self.assertEqual(len(MODULE.PATCHER.DESKTOP_ACTIONS), 7)
        self.assertIn("dpkg-deb", SCRIPT.read_text(encoding="utf-8"))
        self.assertIn("rpm2cpio", SCRIPT.read_text(encoding="utf-8"))
        self.assertIn("rpmbuild", SCRIPT.read_text(encoding="utf-8"))

    def test_maps_prerelease_to_rpm_version_and_release(self) -> None:
        self.assertEqual(
            MODULE.rpm_fields("0.5.3-beta.19+20260924"),
            ("0.5.3", "0.beta.19.20260924"),
        )
        self.assertEqual(
            MODULE.rpm_fields("0.5.3-beta.19"),
            ("0.5.3", "0.beta.19"),
        )

    def test_release_workflow_packages_patches_and_verifies_rpm(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("--targets deb,appimage", workflow)
        self.assertIn("patch-rpm-desktop.py", workflow)
        self.assertIn("--version", workflow)


if __name__ == "__main__":
    unittest.main()
