import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]
APP_ID = "io.github.vincentzyuapps.dartflutterdemo"
WRAPPER = (
    ROOT / "scripts" / "ci" / "packaging" / "linux" / "appimagetool-wrapper.sh"
)
VERIFIER = (
    ROOT
    / "scripts"
    / "ci"
    / "packaging"
    / "linux"
    / "verify-appimage-desktop.py"
)

# Desktop entry as flutter_app_packager 0.6.11 writes it into an AppImage: the
# [Desktop Entry] group is followed by one group per configured action.
DESKTOP_ENTRY = """[Desktop Entry]
Name=DartFlutterDemo
GenericName=DartFlutterDemo
Exec=LD_LIBRARY_PATH=usr/lib dart_flutter_demo %u
Icon=dart_flutter_demo
Type=Application
StartupNotify=true
Categories=Development;Utility;
Keywords=Dart;Flutter;Demo;
Actions=System;Dialog;

[Desktop Action System]
Name=System Info
Exec=LD_LIBRARY_PATH=usr/lib dart_flutter_demo --tab=system %u

[Desktop Action Dialog]
Name=Dialog Lab
Exec=LD_LIBRARY_PATH=usr/lib dart_flutter_demo --tab=dialog %u
"""

SPEC = importlib.util.spec_from_file_location("verify_appimage_desktop", VERIFIER)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class AppImageToolWrapperTests(unittest.TestCase):
    def run_wrapper(self, desktop_entry: str) -> tuple[str, list[str], list[str]]:
        """Runs the wrapper on a fake AppDir, returning the patched arguments."""
        test_root = ROOT / "tmp" / "test-appimagetool-wrapper"
        shutil.rmtree(test_root, ignore_errors=True)
        self.addCleanup(shutil.rmtree, test_root, ignore_errors=True)

        app_dir = test_root / "Demo.AppDir"
        library_dir = app_dir / "usr" / "lib"
        library_dir.mkdir(parents=True)
        (app_dir / "AppRun").write_text("#!/usr/bin/env bash\n", encoding="utf-8")
        desktop_file = app_dir / "dart_flutter_demo.desktop"
        # The AppDir is built on Linux, so the fixture has to keep Unix line
        # endings even when the suite runs on Windows.
        desktop_file.write_text(desktop_entry, encoding="utf-8", newline="\n")
        for name in ("libstdc++.so.6", "libgcc_s.so.1"):
            (library_dir / name).write_text("bundled", encoding="utf-8")

        fake_tool = test_root / "appimagetool.real"
        arguments_file = test_root / "arguments.txt"
        fake_tool.write_text(
            '#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "$WRAPPER_ARGS_FILE"\n',
            encoding="utf-8",
        )
        fake_tool.chmod(0o755)

        output = test_root / "demo.AppImage"
        arguments = ["--no-appstream", app_dir.as_posix(), output.as_posix()]
        environment = os.environ.copy()
        environment["APPIMAGETOOL_REAL"] = fake_tool.as_posix()
        environment["WRAPPER_ARGS_FILE"] = arguments_file.as_posix()

        subprocess.run(
            ["bash", WRAPPER.as_posix(), *arguments],
            check=True,
            env=environment,
        )

        self.assertFalse((library_dir / "libstdc++.so.6").exists())
        self.assertFalse((library_dir / "libgcc_s.so.1").exists())
        return (
            desktop_file.read_text(encoding="utf-8"),
            arguments_file.read_text(encoding="utf-8").splitlines(),
            arguments,
        )

    def test_completes_the_window_class_inside_the_main_group(self) -> None:
        patched, forwarded, arguments = self.run_wrapper(DESKTOP_ENTRY)

        groups = MODULE.parse_groups(patched)
        # Appending the key would land it in the last [Desktop Action] group,
        # where the dock never reads it.
        self.assertEqual(groups["Desktop Entry"].get("StartupWMClass"), APP_ID)
        self.assertNotIn("StartupWMClass", groups["Desktop Action Dialog"])
        self.assertEqual(forwarded, arguments)

    def test_keeps_an_entry_that_already_declares_the_window_class(self) -> None:
        once, _, _ = self.run_wrapper(DESKTOP_ENTRY)
        twice, _, _ = self.run_wrapper(once)

        self.assertEqual(twice, once)
        self.assertEqual(twice.count("StartupWMClass="), 1)

    def test_completes_an_entry_without_action_groups(self) -> None:
        without_actions = DESKTOP_ENTRY.split("\n\n[Desktop Action System]")[0] + "\n"

        patched, _, _ = self.run_wrapper(without_actions)

        groups = MODULE.parse_groups(patched)
        self.assertEqual(groups["Desktop Entry"].get("StartupWMClass"), APP_ID)


if __name__ == "__main__":
    unittest.main()
