from __future__ import annotations

import argparse
import plistlib
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path


APP_ID = "io.github.vincentzyuapps.dartflutterdemo"
DISPLAY_NAME = "DartFlutterDemo"


def copy_directory_contents(source: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    for item in source.iterdir():
        target = destination / item.name
        if item.is_dir():
            shutil.copytree(item, target, dirs_exist_ok=True)
        else:
            shutil.copy2(item, target)


def configure_android(repo: Path, generated: Path) -> None:
    android = generated / "android"
    main = android / "app" / "src" / "main"
    package_path = main / "kotlin" / Path(*APP_ID.split("."))
    package_path.mkdir(parents=True, exist_ok=True)
    for kotlin in (main / "kotlin").rglob("*.kt"):
        kotlin.unlink()
    shutil.copy2(
        repo / "scripts" / "platform_bootstrap" / "android" / "MainActivity.kt",
        package_path / "MainActivity.kt",
    )
    shutil.copy2(
        repo / "scripts" / "platform_bootstrap" / "android" / "DemoAppWidgetProvider.kt",
        package_path / "DemoAppWidgetProvider.kt",
    )

    res = main / "res"
    (res / "layout").mkdir(parents=True, exist_ok=True)
    (res / "xml").mkdir(parents=True, exist_ok=True)
    shutil.copy2(
        repo / "scripts" / "platform_bootstrap" / "android" / "demo_widget.xml",
        res / "layout" / "demo_widget.xml",
    )
    shutil.copy2(
        repo / "scripts" / "platform_bootstrap" / "android" / "demo_widget_info.xml",
        res / "xml" / "demo_widget_info.xml",
    )
    values = res / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "strings.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n    <string name="app_name">DartFlutterDemo</string>\n</resources>\n',
        encoding="utf-8",
    )

    manifest_path = main / "AndroidManifest.xml"
    ET.register_namespace("android", "http://schemas.android.com/apk/res/android")
    tree = ET.parse(manifest_path)
    root = tree.getroot()
    application = root.find("application")
    if application is None:
        raise RuntimeError("Android manifest has no application element")
    android_name = "{http://schemas.android.com/apk/res/android}name"
    android_resource = "{http://schemas.android.com/apk/res/android}resource"
    android_exported = "{http://schemas.android.com/apk/res/android}exported"
    android_label = "{http://schemas.android.com/apk/res/android}label"
    application.set(android_label, "@string/app_name")
    receiver = ET.SubElement(
        application,
        "receiver",
        {android_name: ".DemoAppWidgetProvider", android_exported: "true"},
    )
    intent_filter = ET.SubElement(receiver, "intent-filter")
    ET.SubElement(
        intent_filter,
        "action",
        {android_name: "android.appwidget.action.APPWIDGET_UPDATE"},
    )
    ET.SubElement(
        receiver,
        "meta-data",
        {
            android_name: "android.appwidget.provider",
            android_resource: "@xml/demo_widget_info",
        },
    )
    ET.indent(tree, space="    ")
    tree.write(manifest_path, encoding="utf-8", xml_declaration=True)

    icons = repo / "assets" / "generated-icons" / "android"
    for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
        source = icons / f"mipmap-{density}" / "ic_launcher.png"
        target = res / f"mipmap-{density}"
        target.mkdir(parents=True, exist_ok=True)
        for name in ("ic_launcher.png", "ic_launcher_round.png"):
            shutil.copy2(source, target / name)


def configure_ios(repo: Path, generated: Path) -> None:
    ios = generated / "ios"
    copy_directory_contents(
        repo / "assets" / "generated-icons" / "ios" / "AppIcon.appiconset",
        ios / "Runner" / "Assets.xcassets" / "AppIcon.appiconset",
    )
    info_path = ios / "Runner" / "Info.plist"
    with info_path.open("rb") as stream:
        info = plistlib.load(stream)
    info["CFBundleDisplayName"] = DISPLAY_NAME
    info["CFBundleName"] = DISPLAY_NAME
    with info_path.open("wb") as stream:
        plistlib.dump(info, stream, sort_keys=False)


def configure_macos(repo: Path, generated: Path) -> None:
    macos = generated / "macos"
    copy_directory_contents(
        repo / "assets" / "generated-icons" / "macos" / "AppIcon.appiconset",
        macos / "Runner" / "Assets.xcassets" / "AppIcon.appiconset",
    )
    config = macos / "Runner" / "Configs" / "AppInfo.xcconfig"
    text = config.read_text(encoding="utf-8")
    text = replace_config(text, "PRODUCT_NAME", DISPLAY_NAME)
    text = replace_config(text, "PRODUCT_BUNDLE_IDENTIFIER", APP_ID)
    config.write_text(text, encoding="utf-8")


def configure_windows(repo: Path, generated: Path) -> None:
    windows = generated / "windows"
    shutil.copy2(
        repo / "assets" / "generated-icons" / "windows" / "app_icon.ico",
        windows / "runner" / "resources" / "app_icon.ico",
    )
    replace_in_file(windows / "CMakeLists.txt", 'set(BINARY_NAME "dartflutterdemo")',
                    'set(BINARY_NAME "dart_flutter_demo")')
    replace_in_file(windows / "runner" / "main.cpp", 'L"dartflutterdemo"',
                    'L"DartFlutterDemo"')
    runner_rc = windows / "runner" / "Runner.rc"
    text = runner_rc.read_text(encoding="utf-8")
    text = text.replace('VALUE "FileDescription", "dartflutterdemo"',
                        'VALUE "FileDescription", "DartFlutterDemo"')
    text = text.replace('VALUE "InternalName", "dartflutterdemo"',
                        'VALUE "InternalName", "dart_flutter_demo"')
    text = text.replace('VALUE "OriginalFilename", "dartflutterdemo.exe"',
                        'VALUE "OriginalFilename", "dart_flutter_demo.exe"')
    text = text.replace('VALUE "ProductName", "dartflutterdemo"',
                        'VALUE "ProductName", "DartFlutterDemo"')
    runner_rc.write_text(text, encoding="utf-8")


def configure_linux(generated: Path) -> None:
    linux = generated / "linux"
    replace_in_file(linux / "CMakeLists.txt", 'set(BINARY_NAME "dartflutterdemo")',
                    'set(BINARY_NAME "dart_flutter_demo")')
    replace_in_file(linux / "CMakeLists.txt", 'set(APPLICATION_ID "io.github.vincentzyuapps.dartflutterdemo")',
                    f'set(APPLICATION_ID "{APP_ID}")')
    replace_in_file(linux / "runner" / "my_application.cc", '"dartflutterdemo"',
                    f'"{DISPLAY_NAME}"')


def replace_config(text: str, key: str, value: str) -> str:
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if line.strip().startswith(f"{key} ="):
            lines[index] = f"{key} = {value}"
            break
    else:
        lines.append(f"{key} = {value}")
    return "\n".join(lines) + "\n"


def replace_in_file(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Expected text not found in {path}: {old}")
    path.write_text(text.replace(old, new), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--generated", type=Path, required=True)
    args = parser.parse_args()
    repo = args.repo.resolve()
    generated = args.generated.resolve()
    configure_android(repo, generated)
    configure_ios(repo, generated)
    configure_macos(repo, generated)
    configure_windows(repo, generated)
    configure_linux(generated)


if __name__ == "__main__":
    main()
