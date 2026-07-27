from __future__ import annotations

import argparse
import shutil
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Pillow is required. Install it with: python -m pip install Pillow"
    ) from exc


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ICON = ROOT / "assets" / "images" / "logo-icon-favicon.png"
OUTPUT_ROOT = ROOT / "assets" / "generated-icons"


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

WINDOWS_SIZES = [16, 24, 32, 48, 64, 128, 256]
LINUX_SIZES = [16, 32, 48, 64, 128, 256, 512]

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


def generate_ios(image: Image.Image, root: Path) -> None:
    ios_root = root / "ios" / "AppIcon.appiconset"
    ios_root.mkdir(parents=True, exist_ok=True)
    for filename, size in IOS_SIZES.items():
        resize_square(image, size).save(ios_root / filename)


def generate_macos(image: Image.Image, root: Path) -> None:
    macos_root = root / "macos" / "AppIcon.appiconset"
    macos_root.mkdir(parents=True, exist_ok=True)
    for filename, size in MACOS_SIZES.items():
        resize_square(image, size).save(macos_root / filename)


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


def main() -> None:
    parser = argparse.ArgumentParser(
        description="从一个 PNG 源图生成各平台应用图标。"
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

    section("清理输出目录")
    ensure_clean_dir(output)
    shutil.copy2(source, output / source.name)
    image.save(output / "logo-icon-favicon.cropped.png")
    print(color(f"已重置输出目录: {output}", GREEN))

    section("生成平台资源")
    generate_android(image, output)
    generate_ios(image, output)
    generate_macos(image, output)
    generate_windows(image, output)
    generate_linux(image, output)

    box(
        [
            color("全部生成完成", GREEN),
            f"android: {len(ANDROID_SIZES)} 张",
            f"ios: {len(IOS_SIZES)} 张",
            f"macos: {len(MACOS_SIZES)} 张",
            "windows: 1 个 ico",
            f"linux: {len(LINUX_SIZES) + 1} 张",
        ]
    )
    print(color(f"输出目录: {output}", DIM))


if __name__ == "__main__":
    main()
