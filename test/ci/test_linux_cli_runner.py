import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / "pubspec.yaml"
RUNNER = ROOT / "linux" / "runner" / "main.cc"
RUNNER_CMAKE = ROOT / "linux" / "runner" / "CMakeLists.txt"
VERSION_TEMPLATE = ROOT / "linux" / "runner" / "application_version.h.in"
WORKFLOW = ROOT / ".github" / "workflows" / "release-publish.yml"
APP = ROOT / "lib" / "app.dart"


class LinuxCliRunnerTests(unittest.TestCase):
    def test_native_queries_short_circuit_before_gtk_initialization(self) -> None:
        source = RUNNER.read_text(encoding="utf-8")

        self.assertIn("bool handle_standalone_cli_query", source)
        self.assertIn('std::strcmp(argv[1], "--help")', source)
        self.assertIn('std::strcmp(argv[1], "--version")', source)
        self.assertIn("if (argc != 2)", source)
        self.assertLess(
            source.index("handle_standalone_cli_query(argc, argv)"),
            source.index("my_application_new()"),
        )

    def test_native_version_is_configured_from_pubspec(self) -> None:
        version = re.search(
            r"^version: (.+)$", PUBSPEC.read_text(encoding="utf-8"), re.MULTILINE
        )
        cmake = RUNNER_CMAKE.read_text(encoding="utf-8")

        self.assertIsNotNone(version)
        self.assertIn('"${CMAKE_CURRENT_SOURCE_DIR}/../../pubspec.yaml"', cmake)
        self.assertIn("configure_file(", cmake)
        self.assertIn("CMAKE_CONFIGURE_DEPENDS", cmake)
        self.assertIn("file(MAKE_DIRECTORY", cmake)
        self.assertIn('@APPLICATION_VERSION@', VERSION_TEMPLATE.read_text(encoding="utf-8"))

    def test_native_help_keeps_the_public_cli_reference(self) -> None:
        source = RUNNER.read_text(encoding="utf-8")

        for line in (
            "DartFlutterDemo command line",
            "-h, --help",
            "-V, --version",
            "--system-info[=json]",
            "--export-logs <target.zip>",
            "--kde-wayland-focus=safe|mpris|all",
        ):
            self.assertIn(line, source)

    def test_release_verifies_the_native_path_without_a_virtual_display(self) -> None:
        workflow = WORKFLOW.read_text(encoding="utf-8")

        self.assertIn('"$binary" --help 2>help.stderr', workflow)
        self.assertIn('"$binary" --version 2>version.stderr', workflow)
        self.assertIn("test ! -s help.stderr", workflow)
        self.assertIn("test ! -s version.stderr", workflow)
        self.assertIn("full_version: ${{ steps.version.outputs.full_version }}", workflow)
        self.assertIn("needs.prepare.outputs.full_version", workflow)

    def test_drawer_header_uses_a_theme_matched_container_pair(self) -> None:
        source = APP.read_text(encoding="utf-8")
        start = source.index("return UserAccountsDrawerHeader(")
        header = source[start : source.index("ListTile(", start)]

        self.assertIn("color: colors.primaryContainer", header)
        self.assertIn("color: colors.onPrimaryContainer", header)
        self.assertIn("onPrimaryContainer.withValues(", header)
        self.assertIn("alpha: 0.78", header)


if __name__ == "__main__":
    unittest.main()
