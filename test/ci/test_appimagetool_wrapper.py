import os
from pathlib import Path
import shutil
import subprocess
import unittest


class AppImageToolWrapperTests(unittest.TestCase):
    def test_finds_appdir_after_options_and_forwards_all_arguments(self) -> None:
        repository = Path(__file__).resolve().parents[2]
        test_root = repository / "tmp" / "test-appimagetool-wrapper"
        shutil.rmtree(test_root, ignore_errors=True)

        try:
            app_dir = test_root / "Demo.AppDir"
            library_dir = app_dir / "usr" / "lib"
            library_dir.mkdir(parents=True)
            (app_dir / "AppRun").write_text("#!/usr/bin/env bash\n", encoding="utf-8")
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
                [
                    "bash",
                    (repository / "scripts/ci/appimagetool-wrapper.sh").as_posix(),
                    *arguments,
                ],
                check=True,
                env=environment,
            )

            self.assertFalse((library_dir / "libstdc++.so.6").exists())
            self.assertFalse((library_dir / "libgcc_s.so.1").exists())
            self.assertEqual(
                arguments_file.read_text(encoding="utf-8").splitlines(),
                arguments,
            )
        finally:
            shutil.rmtree(test_root, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
