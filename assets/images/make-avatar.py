from pathlib import Path

from PIL import Image, ImageOps

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"
RED = "\033[31m"


def color(text: str, code: str) -> str:
    return f"{code}{text}{RESET}"


def banner(title: str) -> None:
    line = "═" * 58
    print(color(f"╔{line}╗", CYAN))
    print(color(f"║ {title:<56} ║", CYAN))
    print(color(f"╚{line}╝", CYAN))


def section(title: str) -> None:
    print(color(f"\n━━ {title} ━━", MAGENTA))


def box(lines: list[str]) -> None:
    width = max(len(line) for line in lines)
    print(color(f"┌{'─' * (width + 2)}┐", BLUE))
    for line in lines:
        print(color(f"│ {line.ljust(width)} │", BLUE))
    print(color(f"└{'─' * (width + 2)}┘", BLUE))


def make_square(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    img = ImageOps.fit(
        img,
        (512, 512),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )
    img.save(dst)


def main() -> None:
    banner("头像方图生成器")
    base = Path(__file__).resolve().parent
    jobs = [
        ("mahiro-pfp-VincentZyu.jpg", "mahiro-pfp-VincentZyu-square.png"),
        ("mahiro-pfp-VincentZyuApps.jpg", "mahiro-pfp-VincentZyuApps-square.png"),
    ]

    for idx, (src_name, dst_name) in enumerate(jobs, start=1):
        section(f"任务 {idx}")
        src = base / src_name
        dst = base / dst_name
        if not src.exists():
            box([color("错误：源文件不存在", RED), str(src)])
            raise SystemExit(1)
        make_square(src, dst)
        box(
            [
                color("完成生成", GREEN),
                f"输入: {src.name}",
                f"输出: {dst.name}",
            ]
        )

    print(color(f"\n{BOLD}全部处理完成。{RESET}", GREEN))
    print(color("说明：输出均为 512x512 RGBA 方图。", DIM))


if __name__ == "__main__":
    main()
