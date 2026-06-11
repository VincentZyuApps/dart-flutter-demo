# Android: inject SystemInfoPlugin import + registration into MainActivity.kt
from pathlib import Path
import re

kt_path = "android/app/src/main/kotlin/com/example/dart_flutter_demo/MainActivity.kt"
with open(kt_path, "r") as f:
    kt = f.read()

kt = kt.replace(
    "import io.flutter.embedding.android.FlutterActivity",
    "import com.example.dart_flutter_demo.SystemInfoPlugin\nimport io.flutter.embedding.android.FlutterActivity",
)
kt = kt.replace(
    "super.configureFlutterEngine(flutterEngine)",
    "super.configureFlutterEngine(flutterEngine)\n        flutterEngine.plugins.add(SystemInfoPlugin())",
)

with open(kt_path, "w") as f:
    f.write(kt)

# Set Android display name
manifest_path = Path("android/app/src/main/AndroidManifest.xml")
manifest = manifest_path.read_text(encoding="utf-8")

manifest, count = re.subn(
    r'(<application\b[^>]*\bandroid:label=")[^"]*(")',
    r"\1DartFlutterDemo\2",
    manifest,
    count=1,
)
if count == 0:
    manifest, count = re.subn(
        r"(<application\b)([^>]*?)>",
        r'\1\2 android:label="DartFlutterDemo">',
        manifest,
        count=1,
    )
    if count == 0:
        raise RuntimeError("Failed to set android:label in AndroidManifest.xml")

manifest_path.write_text(manifest, encoding="utf-8")

# Fix Maven Central 403: ensure google() is before mavenCentral() in settings.gradle.kts
settings_path = Path("android/settings.gradle.kts")
if settings_path.exists():
    lines = settings_path.read_text(encoding="utf-8").splitlines(keepends=True)
    result = []
    for i, line in enumerate(lines):
        if "mavenCentral()" in line and "google()" not in line:
            has_google = False
            for j in range(i - 1, -1, -1):
                prev = lines[j].strip()
                if prev.startswith("repositories") and "{" in prev:
                    break
                if "google()" in prev:
                    has_google = True
                    break
            if not has_google:
                indent = line[: len(line) - len(line.lstrip())]
                result.append(indent + "google()\n")
        result.append(line)
    settings_path.write_text("".join(result), encoding="utf-8")
