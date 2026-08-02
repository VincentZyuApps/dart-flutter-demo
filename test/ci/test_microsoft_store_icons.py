import json
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ICONS_ROOT = ROOT / "assets" / "icons"
STORE_ROOT = ICONS_ROOT / "windows" / "MicrosoftStore"

EXPECTED_IMAGES = {
    "store-poster-720x1080.png": ((720, 1080), 50_000_000),
    "store-poster-1440x2160.png": ((1440, 2160), 50_000_000),
    "store-box-art-1080x1080.png": ((1080, 1080), 50_000_000),
    "store-box-art-2160x2160.png": ((2160, 2160), 50_000_000),
    "store-display-icon-300x300.png": ((300, 300), 5_000_000),
    "store-display-icon-150x150.png": ((150, 150), 5_000_000),
    "store-display-icon-71x71.png": ((71, 71), 5_000_000),
}


def read_png_size(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG file: {path}")
    return struct.unpack(">II", header[16:24])


class MicrosoftStoreIconTests(unittest.TestCase):
    def test_generated_store_images_match_portal_requirements(self) -> None:
        actual_names = {path.name for path in STORE_ROOT.glob("*.png")}
        self.assertEqual(actual_names, set(EXPECTED_IMAGES))

        for filename, (expected_size, max_bytes) in EXPECTED_IMAGES.items():
            with self.subTest(filename=filename):
                path = STORE_ROOT / filename
                self.assertEqual(read_png_size(path), expected_size)
                self.assertLess(path.stat().st_size, max_bytes)


class PlatformIconMigrationTests(unittest.TestCase):
    def test_platform_icon_inputs_exist_under_icons(self) -> None:
        expected_paths = [
            ICONS_ROOT / "windows" / "app_icon.ico",
            *(
                ICONS_ROOT
                / "android"
                / f"mipmap-{density}"
                / "ic_launcher.png"
                for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")
            ),
        ]
        for path in expected_paths:
            with self.subTest(path=path):
                self.assertTrue(path.is_file())

    def test_xcode_catalogs_reference_existing_generated_images(self) -> None:
        catalogs = [
            ICONS_ROOT / "ios" / "AppIcon.appiconset" / "Contents.json",
            ICONS_ROOT / "macos" / "AppIcon.appiconset" / "Contents.json",
        ]
        for catalog in catalogs:
            with self.subTest(catalog=catalog):
                contents = json.loads(catalog.read_text(encoding="utf-8"))
                for image in contents["images"]:
                    self.assertTrue((catalog.parent / image["filename"]).is_file())

    def test_legacy_icon_directory_is_absent(self) -> None:
        legacy_directory = "generated" + "-icons"
        self.assertFalse((ROOT / "assets" / legacy_directory).exists())


if __name__ == "__main__":
    unittest.main()
