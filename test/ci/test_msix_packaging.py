import importlib.util
import hashlib
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "ci" / "packaging" / "windows" / "build-msix.py"
SPEC = importlib.util.spec_from_file_location("build_msix", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class StoreVersionTests(unittest.TestCase):
    def test_maps_supported_release_stages(self) -> None:
        cases = {
            "1.2.3-alpha.2+20260727": "2026.727.10002.0",
            "1.2.3-beta.10+20260727": "2026.727.20010.0",
            "1.2.3-rc.3+20260727": "2026.727.30003.0",
            "1.2.3+20260727": "2026.727.60000.0",
        }
        for full_version, expected in cases.items():
            with self.subTest(full_version=full_version):
                self.assertEqual(
                    MODULE.store_version_from_pubspec(full_version), expected
                )

    def test_rejects_missing_date_and_unknown_stage(self) -> None:
        for full_version in ("1.2.3-beta.10", "1.2.3-preview.1+20260727"):
            with self.subTest(full_version=full_version):
                with self.assertRaises(ValueError):
                    MODULE.store_version_from_pubspec(full_version)

    def test_rejects_invalid_date_and_zero_prerelease_sequence(self) -> None:
        for full_version in ("1.2.3-beta.1+20260230", "1.2.3-beta.0+20260727"):
            with self.subTest(full_version=full_version):
                with self.assertRaises(ValueError):
                    MODULE.store_version_from_pubspec(full_version)


class ReleaseMetadataTests(unittest.TestCase):
    def test_validates_release_metadata_and_checksum(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            package = Path(temporary_directory) / "store.msix"
            package.write_bytes(b"verified-msix")
            full_version = "0.5.0-beta.14+20260812"
            metadata = {
                "application_version": "0.5.0-beta.14",
                "pubspec_version": full_version,
                "store_version": "2026.812.20014.0",
                "architecture": "x64",
                "identity_name": "VincentZyu.dart-flutter-demo",
                "publisher": "CN=publisher",
                "publisher_display_name": "VincentZyu",
                "display_name": "DartFlutterDemo",
                "signed": False,
                "filename": package.name,
                "size_bytes": package.stat().st_size,
                "sha256": hashlib.sha256(package.read_bytes()).hexdigest(),
            }

            MODULE.validate_release_metadata(
                metadata,
                package,
                full_version=full_version,
                identity_name="VincentZyu.dart-flutter-demo",
                publisher="CN=publisher",
                publisher_display_name="VincentZyu",
                display_name="DartFlutterDemo",
            )

    def test_rejects_tampered_release_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            package = Path(temporary_directory) / "store.msix"
            package.write_bytes(b"verified-msix")
            metadata = {
                "application_version": "0.5.0-beta.14",
                "pubspec_version": "0.5.0-beta.14+20260812",
                "store_version": "2026.812.20014.0",
                "architecture": "x64",
                "identity_name": "wrong.identity",
                "publisher": "CN=publisher",
                "publisher_display_name": "VincentZyu",
                "display_name": "DartFlutterDemo",
                "signed": False,
                "filename": package.name,
                "size_bytes": package.stat().st_size,
                "sha256": hashlib.sha256(package.read_bytes()).hexdigest(),
            }

            with self.assertRaisesRegex(ValueError, "identity_name"):
                MODULE.validate_release_metadata(
                    metadata,
                    package,
                    full_version="0.5.0-beta.14+20260812",
                    identity_name="VincentZyu.dart-flutter-demo",
                    publisher="CN=publisher",
                    publisher_display_name="VincentZyu",
                    display_name="DartFlutterDemo",
                )


class WindowsSdkTests(unittest.TestCase):
    def test_windows_sdk_versions_are_compared_numerically(self) -> None:
        older = Path("Windows Kits/10/bin/10.0.9.0/x64/MakeAppx.exe")
        newer = Path("Windows Kits/10/bin/10.0.26100.0/x64/MakeAppx.exe")

        self.assertGreater(
            MODULE.windows_sdk_version(newer),
            MODULE.windows_sdk_version(older),
        )


class ManifestTests(unittest.TestCase):
    def test_manifest_uses_store_identity_and_x64_full_trust(self) -> None:
        manifest = MODULE.render_manifest(
            store_version="2026.727.20010.0",
            identity_name="VincentZyu.dart-flutter-demo",
            publisher="CN=A12FF185-DB00-4CAC-ADE2-C501823ECC8F",
            publisher_display_name="VincentZyu",
            display_name="DartFlutterDemo",
        )
        root = ET.fromstring(manifest)
        ns = {"m": MODULE.MSIX_NS, "rescap": MODULE.RESCAP_NS}
        identity = root.find("m:Identity", ns)
        self.assertIsNotNone(identity)
        assert identity is not None
        self.assertEqual(identity.get("Name"), "VincentZyu.dart-flutter-demo")
        self.assertEqual(identity.get("Version"), "2026.727.20010.0")
        self.assertEqual(identity.get("ProcessorArchitecture"), "x64")

        application = root.find("m:Applications/m:Application", ns)
        self.assertIsNotNone(application)
        assert application is not None
        self.assertEqual(application.get("Executable"), "dart_flutter_demo.exe")
        self.assertEqual(application.get("EntryPoint"), "Windows.FullTrustApplication")

        capability = root.find("m:Capabilities/rescap:Capability", ns)
        self.assertIsNotNone(capability)
        assert capability is not None
        self.assertEqual(capability.get("Name"), "runFullTrust")


if __name__ == "__main__":
    unittest.main()
