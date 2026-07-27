# python ./download-release.py --proxy http://127.0.0.1:7890 --path X:\packs\dart-flutter-demo-showcase

import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.request
from pathlib import Path


class C:
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BLUE = "\033[94m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RESET = "\033[0m"


def init_colors():
    if sys.platform == "win32":
        import ctypes

        h = ctypes.windll.kernel32.GetStdHandle(-11)
        m = ctypes.c_uint32()
        if ctypes.windll.kernel32.GetConsoleMode(h, ctypes.byref(m)):
            ctypes.windll.kernel32.SetConsoleMode(h, m.value | 0x0004)


GITHUB_API = "https://api.github.com/repos/VincentZyuApps/dart-flutter-demo/releases"
PER_PAGE = 5


def parse_args():
    parser = argparse.ArgumentParser(description="Download GitHub release assets")
    parser.add_argument("--proxy", help="Proxy URL, e.g. http://127.0.0.1:7890")
    parser.add_argument(
        "--list-only", action="store_true", help="Only list assets, do not download"
    )
    parser.add_argument("--path", help="Download directory (default: current dir)")
    return parser.parse_args()


def resolve_proxy(cli_proxy):
    if cli_proxy:
        return cli_proxy
    for var in ("HTTPS_PROXY", "https_proxy", "HTTP_PROXY", "http_proxy"):
        val = os.environ.get(var)
        if val:
            return val
    return None


def build_opener(proxy_url):
    if proxy_url:
        proxy_handler = urllib.request.ProxyHandler(
            {
                "http": proxy_url,
                "https": proxy_url,
            }
        )
        return urllib.request.build_opener(proxy_handler)
    return urllib.request.build_opener()


def fetch_releases(opener):
    req = urllib.request.Request(GITHUB_API + f"?per_page={PER_PAGE}")
    req.add_header("User-Agent", "download-release-script")
    req.add_header("Accept", "application/vnd.github.v3+json")
    try:
        with opener.open(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"HTTP error: {e.code} {e.reason}")
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Network error: {e.reason}")
        sys.exit(1)


def format_size(size_bytes):
    for unit in ("B", "KB", "MB", "GB"):
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"


def interactive_select(releases):
    if not releases:
        print("No releases found.")
        sys.exit(1)

    published = []
    for r in releases:
        raw = r.get("published_at", "") or r.get("created_at", "")
        if raw:
            published.append(raw[:10])
        else:
            published.append("unknown")

    lines = []
    for i, (r, d) in enumerate(zip(releases, published), 1):
        tag = r["tag_name"]
        name = r.get("name") or ""
        line = f" {i}) {tag}"
        if name:
            line += f"  {name}"
        line += f"  ({d})"
        lines.append((line, r))

    print(f"\n{C.CYAN}🔍 Fetching latest {PER_PAGE} releases...{C.RESET}\n")
    for line, _ in lines:
        print(f"  {C.CYAN}{line}{C.RESET}")

    print(
        f"\n{C.CYAN}Enter number (1-{len(lines)}) or press Enter for 1: {C.RESET}",
        end="",
        flush=True,
    )

    choice = sys.stdin.readline().strip()
    if not choice:
        idx = 0
    else:
        try:
            idx = int(choice) - 1
            if idx < 0 or idx >= len(lines):
                print(f"{C.YELLOW}⚠️ Invalid choice, defaulting to 1{C.RESET}")
                idx = 0
        except ValueError:
            print(f"{C.YELLOW}⚠️ Invalid input, defaulting to 1{C.RESET}")
            idx = 0

    return releases[idx]


def print_assets(release):
    tag = release["tag_name"]
    assets = release.get("assets", [])
    print(f"\n{C.CYAN}{'=' * 60}{C.RESET}")
    print(f"  {C.BOLD}📋 Release: {tag}{C.RESET}")
    print(f"{C.CYAN}{'=' * 60}{C.RESET}")
    for a in assets:
        name = a["name"]
        size = a.get("size", 0)
        print(f"  {C.BOLD}{name}{C.RESET}  {C.DIM}({format_size(size)}){C.RESET}")
    print(f"{C.CYAN}{'=' * 60}{C.RESET}\n")


def verify_sha256(filepath, expected_sha):
    sha256 = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha256.update(chunk)
    return sha256.hexdigest() == expected_sha.lower()


def download_assets(opener, release, dest_dir, verify=True):
    tag = release["tag_name"]
    assets = release.get("assets", [])
    if not assets:
        print(f"{C.YELLOW}📭 No assets in this release.{C.RESET}")
        return

    dest = Path(dest_dir) / tag
    dest.mkdir(parents=True, exist_ok=True)

    for a in assets:
        name = a["name"]
        url = a["browser_download_url"]
        size = a.get("size", 0)

        filepath = dest / name
        if filepath.exists():
            print(f"  {C.YELLOW}⏭️ [SKIP] {name} — already exists{C.RESET}")
            continue

        print(f"  {C.BOLD}⬇️ [DOWNLOAD] {name}  ({format_size(size)}){C.RESET}")

        try:
            req = urllib.request.Request(url)
            req.add_header("User-Agent", "download-release-script")
            req.add_header("Accept", "application/octet-stream")

            with opener.open(req, timeout=120) as resp:
                total = int(resp.headers.get("Content-Length", 0) or size)
                downloaded = 0
                start_time = time.time()

                with open(filepath, "wb") as f:
                    while True:
                        chunk = resp.read(65536)
                        if not chunk:
                            break
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total:
                            pct = downloaded * 100 / total
                            elapsed = time.time() - start_time
                            speed = downloaded / elapsed if elapsed > 0 else 0
                            bar_len = 30
                            filled = int(bar_len * downloaded / total)
                            sys.stdout.write(
                                f"\r    [{C.GREEN}{'█' * filled}{C.DIM}{'─' * (bar_len - filled)}{C.RESET}] {C.BOLD}{pct:5.1f}%{C.RESET}  {C.DIM}{format_size(speed)}/s{C.RESET}  "
                            )
                            sys.stdout.flush()

            sys.stdout.write("\n")
            sys.stdout.flush()

            # try sha256 from release body
            body = release.get("body") or ""
            exp_sha = None
            for line in body.splitlines():
                line = line.strip()
                if name in line:
                    for m in re.finditer(r"sha256:\s*([a-fA-F0-9]{64})", body):
                        exp_sha = m.group(1)
                        break
                    if exp_sha:
                        break

            if exp_sha:
                actual = hashlib.sha256()
                with open(filepath, "rb") as f:
                    for chunk in iter(lambda: f.read(65536), b""):
                        actual.update(chunk)
                if actual.hexdigest() == exp_sha.lower():
                    print(f"    {C.GREEN}✅ SHA256 ✓{C.RESET}")
                else:
                    print(
                        f"    {C.RED}❌ SHA256 ✗ mismatch — expected {exp_sha[:16]}..., got {actual.hexdigest()[:16]}...{C.RESET}"
                    )

        except Exception as e:
            print(f"    {C.RED}💥 FAILED: {e}{C.RESET}")
            if filepath.exists():
                filepath.unlink()


def main():
    init_colors()
    args = parse_args()
    proxy = resolve_proxy(args.proxy)

    if proxy:
        print(f"{C.BLUE}🌐 Using proxy: {proxy}{C.RESET}")
    else:
        print(f"{C.BLUE}ℹ️ No proxy configured{C.RESET}")

    opener = build_opener(proxy)
    releases = fetch_releases(opener)
    selected = interactive_select(releases)

    print_assets(selected)

    if args.list_only:
        return

    dest_dir = args.path
    if not dest_dir:
        default = os.getcwd()
        ans = input(f"{C.CYAN}📂 Download path [{default}]: {C.RESET}").strip()
        dest_dir = ans if ans else default

    ans = input(f"{C.CYAN}📥 Download all assets? [Y/n]: {C.RESET}").strip().lower()
    if ans in ("", "y", "yes"):
        download_assets(opener, selected, dest_dir)
        print(f"\n{C.GREEN}✅ Done!{C.RESET}")
    else:
        print(f"{C.YELLOW}⏭️ Skipped.{C.RESET}")


if __name__ == "__main__":
    main()
