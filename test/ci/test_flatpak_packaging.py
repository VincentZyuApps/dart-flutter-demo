import importlib.util
import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APP_ID = "io.github.vincentzyuapps.dartflutterdemo"
FLATPAK_DIR = ROOT / "linux" / "packaging" / "flatpak"
MANIFEST = FLATPAK_DIR / f"{APP_ID}.yml"
METADATA_TEMPLATE = FLATPAK_DIR / f"{APP_ID}.metainfo.xml.in"
DESKTOP_FILE = FLATPAK_DIR / f"{APP_ID}.desktop"
WORKFLOW = ROOT / ".github" / "workflows" / "check-flatpak-repo.yml"
RELEASE_WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"
VERIFY_SCRIPT = (
    ROOT
    / "scripts"
    / "ci"
    / "packaging"
    / "linux"
    / "verify-flatpak-package.sh"
)
SCRIPT = (
    ROOT
    / "scripts"
    / "ci"
    / "packaging"
    / "linux"
    / "render-flatpak-metadata.py"
)
SPEC = importlib.util.spec_from_file_location("render_flatpak_metadata", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class FlatpakMetadataTests(unittest.TestCase):
    def test_renders_development_release_from_pubspec_version(self) -> None:
        rendered = MODULE.render_metadata(
            METADATA_TEMPLATE.read_text(encoding="utf-8"),
            "0.5.0-beta.13+20260802",
        )
        root = ET.fromstring(rendered)
        release = root.find("./releases/release")
        self.assertIsNotNone(release)
        assert release is not None
        self.assertEqual(release.get("version"), "0.5.0-beta.13")
        self.assertEqual(release.get("date"), "2026-08-02")
        self.assertEqual(release.get("type"), "development")

    def test_renders_stable_release_without_changing_flatpak_branch(self) -> None:
        rendered = MODULE.render_metadata(
            METADATA_TEMPLATE.read_text(encoding="utf-8"),
            "1.0.0+20270102",
        )
        release = ET.fromstring(rendered).find("./releases/release")
        self.assertIsNotNone(release)
        assert release is not None
        self.assertEqual(release.get("version"), "1.0.0")
        self.assertEqual(release.get("date"), "2027-01-02")
        self.assertEqual(release.get("type"), "stable")

    def test_rejects_missing_or_invalid_build_date(self) -> None:
        for version in ("0.5.0-beta.13", "0.5.0-beta.13+20260230"):
            with self.subTest(version=version):
                with self.assertRaises(ValueError):
                    MODULE.release_fields(version)


class FlatpakConfigurationTests(unittest.TestCase):
    def test_manifest_uses_stable_channel_and_strict_permissions(self) -> None:
        manifest = MANIFEST.read_text(encoding="utf-8")
        self.assertIn(f"app-id: {APP_ID}", manifest)
        self.assertIn("runtime-version: '25.08'", manifest)
        self.assertIn("--socket=fallback-x11", manifest)
        self.assertIn("--socket=wayland", manifest)
        self.assertIn("--device=dri", manifest)
        self.assertNotIn("--filesystem=host", manifest)
        self.assertNotIn("--filesystem=home", manifest)
        self.assertNotIn("--device=all", manifest)
        self.assertNotIn("--socket=system-bus", manifest)
        self.assertNotIn("--socket=session-bus", manifest)

    def test_desktop_identity_matches_manifest(self) -> None:
        entries = dict(
            line.split("=", 1)
            for line in DESKTOP_FILE.read_text(encoding="utf-8").splitlines()
            if "=" in line
        )
        self.assertEqual(entries["Icon"], APP_ID)
        self.assertEqual(entries["StartupWMClass"], APP_ID)
        self.assertEqual(entries["Exec"], "dart-flutter-demo")

    def test_package_only_workflow_is_manual_and_pinned(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("workflow_dispatch:", workflow)
        self.assertNotIn("pull_request:", workflow)
        self.assertIn("branch: stable", workflow)
        self.assertIn(
            "flatpak/flatpak-github-actions/flatpak-builder@"
            "bf5cafdfd97dcf5a89c7475bbc86a616e1f86acb",
            workflow,
        )
        self.assertIn("verify-flatpak-package.sh", workflow)
        self.assertIn("retention-days: 7", workflow)

        verifier = VERIFY_SCRIPT.read_text(encoding="utf-8")
        self.assertIn(
            '"/app/share/metainfo/${APP_ID}.metainfo.xml"',
            verifier,
        )
        self.assertIn('<release version=\\"$EXPECTED_VERSION\\"', verifier)
        self.assertNotIn("--show-version", verifier)
        self.assertIn("filesystems=(host|home)", verifier)
        self.assertIn("timeout --signal=TERM --kill-after=5s 20s", verifier)

    def test_release_workflow_packages_flatpak_and_gates_repository_request(self) -> None:
        workflow = RELEASE_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("--token build-publish", workflow)
        self.assertIn("should_publish_external_channels", workflow)
        self.assertIn("name: release-flatpak-x64", workflow)
        self.assertIn(
            "dart-flutter-demo-linux-x64-v${{ needs.prepare.outputs.version }}.flatpak",
            workflow,
        )
        self.assertIn(
            "flatpak/flatpak-github-actions/flatpak-builder@"
            "bf5cafdfd97dcf5a89c7475bbc86a616e1f86acb",
            workflow,
        )
        self.assertIn("verify-flatpak-package.sh", workflow)
        self.assertIn("flatpak-publish-request.json", workflow)
        self.assertIn("schema_version: 1", workflow)
        self.assertIn("publish-microsoft-store:", workflow)


if __name__ == "__main__":
    unittest.main()
