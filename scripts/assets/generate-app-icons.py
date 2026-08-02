# /// script
# requires-python = ">=3.10"
# dependencies = ["Pillow==11.3.0"]
# ///

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Pillow is required. Run this script with: "
        "uv run scripts/assets/generate-app-icons.py"
    ) from exc


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ICON = ROOT / "assets" / "images" / "logo-icon-favicon.png"
# assets/icons 是生成产物目录，不应手工修改；请修改源图或本脚本后重新生成。
OUTPUT_ROOT = ROOT / "assets" / "icons"


ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

IOS_CONTENTS = [
    ("20x20", "iphone", "Icon-App-20x20@2x.png", "2x"),
    ("20x20", "iphone", "Icon-App-20x20@3x.png", "3x"),
    ("29x29", "iphone", "Icon-App-29x29@2x.png", "2x"),
    ("29x29", "iphone", "Icon-App-29x29@3x.png", "3x"),
    ("40x40", "iphone", "Icon-App-40x40@2x.png", "2x"),
    ("40x40", "iphone", "Icon-App-40x40@3x.png", "3x"),
    ("60x60", "iphone", "Icon-App-60x60@2x.png", "2x"),
    ("60x60", "iphone", "Icon-App-60x60@3x.png", "3x"),
    ("20x20", "ipad", "Icon-App-20x20@1x.png", "1x"),
    ("20x20", "ipad", "Icon-App-20x20@2x.png", "2x"),
    ("29x29", "ipad", "Icon-App-29x29@1x.png", "1x"),
    ("29x29", "ipad", "Icon-App-29x29@2x.png", "2x"),
    ("40x40", "ipad", "Icon-App-40x40@1x.png", "1x"),
    ("40x40", "ipad", "Icon-App-40x40@2x.png", "2x"),
    ("76x76", "ipad", "Icon-App-76x76@1x.png", "1x"),
    ("76x76", "ipad", "Icon-App-76x76@2x.png", "2x"),
    ("83.5x83.5", "ipad", "Icon-App-83.5x83.5@2x.png", "2x"),
    ("1024x1024", "ios-marketing", "Icon-App-1024x1024@1x.png", "1x"),
]

MACOS_SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}

MACOS_CONTENTS = [
    ("16x16", "mac", "icon_16x16.png", "1x"),
    ("16x16", "mac", "icon_16x16@2x.png", "2x"),
    ("32x32", "mac", "icon_32x32.png", "1x"),
    ("32x32", "mac", "icon_32x32@2x.png", "2x"),
    ("128x128", "mac", "icon_128x128.png", "1x"),
    ("128x128", "mac", "icon_128x128@2x.png", "2x"),
    ("256x256", "mac", "icon_256x256.png", "1x"),
    ("256x256", "mac", "icon_256x256@2x.png", "2x"),
    ("512x512", "mac", "icon_512x512.png", "1x"),
    ("512x512", "mac", "icon_512x512@2x.png", "2x"),
]

WINDOWS_SIZES = [16, 24, 32, 48, 64, 128, 256]
LINUX_SIZES = [16, 32, 48, 64, 128, 256, 512]

MICROSOFT_STORE_POSTER_SIZES = [(720, 1080), (1440, 2160)]
MICROSOFT_STORE_BOX_ART_SIZES = [(1080, 1080), (2160, 2160)]
MICROSOFT_STORE_DISPLAY_ICON_SIZES = [(300, 300), (150, 150), (71, 71)]
MICROSOFT_STORE_BACKGROUND = (15, 23, 42, 255)
MICROSOFT_STORE_ART_MAX_BYTES = 50_000_000
MICROSOFT_STORE_ICON_MAX_BYTES = 5_000_000

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"


def color(text: str, code: str) -> str:
    return f"{code}{text}{RESET}"


def banner(title: str) -> None:
    line = "═" * 68
    print(color(f"╔{line}╗", CYAN))
    print(color(f"║ {title:<66} ║", CYAN))
    print(color(f"╚{line}╝", CYAN))


def section(title: str) -> None:
    print(color(f"\n━━ {title} ━━", MAGENTA))


def box(lines: list[str]) -> None:
    width = max(len(line) for line in lines)
    print(color(f"┌{'─' * (width + 2)}┐", BLUE))
    for line in lines:
        print(color(f"│ {line.ljust(width)} │", BLUE))
    print(color(f"└{'─' * (width + 2)}┘", BLUE))


def resize_square(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.Resampling.LANCZOS)


def crop_center_square_with_margin(
    image: Image.Image, margin_ratio: float = 0.1
) -> Image.Image:
    if not 0 <= margin_ratio < 0.5:
        raise ValueError("margin_ratio must be in the range [0, 0.5).")

    width, height = image.size
    margin_x = int(round(width * margin_ratio))
    margin_y = int(round(height * margin_ratio))

    left = margin_x
    top = margin_y
    right = width - margin_x
    bottom = height - margin_y

    if right <= left or bottom <= top:
        raise ValueError("Crop margins are too large for the source image.")

    inner_width = right - left
    inner_height = bottom - top
    square_size = min(inner_width, inner_height)

    center_x = width / 2
    center_y = height / 2
    square_left = int(round(center_x - square_size / 2))
    square_top = int(round(center_y - square_size / 2))
    square_right = square_left + square_size
    square_bottom = square_top + square_size

    return image.crop((square_left, square_top, square_right, square_bottom))


def get_crop_box(image: Image.Image, margin_ratio: float) -> tuple[int, int, int, int]:
    width, height = image.size
    margin_x = int(round(width * margin_ratio))
    margin_y = int(round(height * margin_ratio))
    inner_left = margin_x
    inner_top = margin_y
    inner_right = width - margin_x
    inner_bottom = height - margin_y
    inner_width = inner_right - inner_left
    inner_height = inner_bottom - inner_top
    square_size = min(inner_width, inner_height)
    center_x = width / 2
    center_y = height / 2
    square_left = int(round(center_x - square_size / 2))
    square_top = int(round(center_y - square_size / 2))
    square_right = square_left + square_size
    square_bottom = square_top + square_size
    return square_left, square_top, square_right, square_bottom


def ensure_clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def generate_android(image: Image.Image, root: Path) -> None:
    android_root = root / "android"
    for folder, size in ANDROID_SIZES.items():
        target_dir = android_root / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        resize_square(image, size).save(target_dir / "ic_launcher.png")


def write_asset_catalog(
    target: Path,
    entries: list[tuple[str, str, str, str]],
) -> None:
    contents = {
        "images": [
            {
                "size": size,
                "idiom": idiom,
                "filename": filename,
                "scale": scale,
            }
            for size, idiom, filename, scale in entries
        ],
        "info": {"version": 1, "author": "xcode"},
    }
    target.write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


def generate_ios(image: Image.Image, root: Path) -> None:
    ios_root = root / "ios" / "AppIcon.appiconset"
    ios_root.mkdir(parents=True, exist_ok=True)
    for filename, size in IOS_SIZES.items():
        resize_square(image, size).save(ios_root / filename)
    write_asset_catalog(ios_root / "Contents.json", IOS_CONTENTS)


def generate_macos(image: Image.Image, root: Path) -> None:
    macos_root = root / "macos" / "AppIcon.appiconset"
    macos_root.mkdir(parents=True, exist_ok=True)
    for filename, size in MACOS_SIZES.items():
        resize_square(image, size).save(macos_root / filename)
    write_asset_catalog(macos_root / "Contents.json", MACOS_CONTENTS)


def generate_windows(image: Image.Image, root: Path) -> None:
    windows_root = root / "windows"
    windows_root.mkdir(parents=True, exist_ok=True)
    ico_target = windows_root / "app_icon.ico"
    image.save(ico_target, format="ICO", sizes=[(size, size) for size in WINDOWS_SIZES])


def generate_linux(image: Image.Image, root: Path) -> None:
    linux_root = root / "linux"
    linux_root.mkdir(parents=True, exist_ok=True)
    for size in LINUX_SIZES:
        resize_square(image, size).save(linux_root / f"app_icon_{size}.png")
    resize_square(image, 512).save(linux_root / "app_icon.png")


def compose_store_image(
    image: Image.Image,
    size: tuple[int, int],
    logo_scale: float,
) -> Image.Image:
    width, height = size
    max_logo_size = (
        max(1, int(round(width * logo_scale))),
        max(1, int(round(height * logo_scale))),
    )
    resize_ratio = min(
        max_logo_size[0] / image.width,
        max_logo_size[1] / image.height,
    )
    logo_size = (
        max(1, int(round(image.width * resize_ratio))),
        max(1, int(round(image.height * resize_ratio))),
    )
    logo = image.resize(logo_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", size, MICROSOFT_STORE_BACKGROUND)
    position = ((width - logo.width) // 2, (height - logo.height) // 2)
    canvas.alpha_composite(logo, position)
    return canvas


def save_store_png(
    image: Image.Image,
    target: Path,
    expected_size: tuple[int, int],
    max_bytes: int,
) -> None:
    image.save(target, format="PNG", optimize=True)
    with Image.open(target) as generated:
        if generated.format != "PNG" or generated.size != expected_size:
            raise RuntimeError(f"Microsoft Store 图片校验失败: {target}")
        if generated.getchannel("A").getextrema() != (255, 255):
            raise RuntimeError(f"Microsoft Store 图片包含透明像素: {target}")
    if target.stat().st_size >= max_bytes:
        limit_mb = max_bytes // 1_000_000
        raise RuntimeError(f"Microsoft Store 图片超过 {limit_mb} MB: {target}")


def generate_microsoft_store(image: Image.Image, root: Path) -> None:
    store_root = root / "windows" / "MicrosoftStore"
    ensure_clean_dir(store_root)

    for width, height in MICROSOFT_STORE_POSTER_SIZES:
        filename = f"store-poster-{width}x{height}.png"
        artwork = compose_store_image(image, (width, height), logo_scale=0.82)
        save_store_png(
            artwork,
            store_root / filename,
            (width, height),
            MICROSOFT_STORE_ART_MAX_BYTES,
        )

    for width, height in MICROSOFT_STORE_BOX_ART_SIZES:
        filename = f"store-box-art-{width}x{height}.png"
        artwork = compose_store_image(image, (width, height), logo_scale=0.84)
        save_store_png(
            artwork,
            store_root / filename,
            (width, height),
            MICROSOFT_STORE_ART_MAX_BYTES,
        )

    for width, height in MICROSOFT_STORE_DISPLAY_ICON_SIZES:
        filename = f"store-display-icon-{width}x{height}.png"
        artwork = compose_store_image(image, (width, height), logo_scale=0.82)
        save_store_png(
            artwork,
            store_root / filename,
            (width, height),
            MICROSOFT_STORE_ICON_MAX_BYTES,
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="从一个 PNG 源图生成 assets/icons 中的各平台应用图标。"
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=SOURCE_ICON,
        help="源 PNG 图标。默认使用 assets/images/logo-icon-favicon.png",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_ROOT,
        help="生成图标的输出目录。",
    )
    parser.add_argument(
        "--microsoft-store-only",
        action="store_true",
        help="仅重建 windows/MicrosoftStore，不清理其他平台的生成资源。",
    )
    args = parser.parse_args()

    banner("应用图标生成器")
    source = args.source.resolve()
    output = args.output.resolve()

    if not source.exists():
        box([color("错误：找不到源图标", RED), str(source)])
        raise SystemExit(1)

    original = Image.open(source).convert("RGBA")
    crop_box = get_crop_box(original, margin_ratio=0.1)
    image = crop_center_square_with_margin(original, margin_ratio=0.1)

    section("输入检查")
    box(
        [
            color("源图标已找到", GREEN),
            f"路径: {source}",
            f"尺寸: {original.width}x{original.height}",
            f"模式: {original.mode}",
        ]
    )

    section("裁剪参数")
    box(
        [
            "边距比例: 10%",
            f"裁剪框: left={crop_box[0]}, top={crop_box[1]}, right={crop_box[2]}, bottom={crop_box[3]}",
            f"裁剪后: {image.width}x{image.height}, mode={image.mode}",
        ]
    )

    if args.microsoft_store_only:
        section("准备 Microsoft Store 输出目录")
        output.mkdir(parents=True, exist_ok=True)
        print(color("只会重建 windows/MicrosoftStore", GREEN))
    else:
        section("清理输出目录")
        ensure_clean_dir(output)
        shutil.copy2(source, output / source.name)
        image.save(output / "logo-icon-favicon.cropped.png")
        print(color(f"已重置输出目录: {output}", GREEN))

    section("生成平台资源")
    if args.microsoft_store_only:
        generate_microsoft_store(image, output)
        summary = [
            color("Microsoft Store 图片生成完成", GREEN),
            "poster: 2 张",
            "box art: 2 张",
            "display icon: 3 张",
        ]
    else:
        generate_android(image, output)
        generate_ios(image, output)
        generate_macos(image, output)
        generate_windows(image, output)
        generate_linux(image, output)
        generate_microsoft_store(image, output)
        summary = [
            color("全部生成完成", GREEN),
            f"android: {len(ANDROID_SIZES)} 张",
            f"ios: {len(IOS_SIZES)} 张",
            f"macos: {len(MACOS_SIZES)} 张",
            "windows: 1 个 ico",
            "Microsoft Store: 7 张 PNG",
            f"linux: {len(LINUX_SIZES) + 1} 张",
        ]

    box(summary)
    print(color(f"输出目录: {output}", DIM))


if __name__ == "__main__":
    main()
