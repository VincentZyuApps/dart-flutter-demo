# 📥 Download Release Tool

⬇️ Download all assets from a GitHub release with a simple interactive CLI.
🧩 Zero third-party dependencies — uses only Python standard library.

## 🚀 Usage

### ⚡ No proxy (default)

```bash
# 💻 Run with default settings (no proxy)
python download_release.py
```

### 🌐 Proxy via --proxy argument (highest priority)

```bash
# 🔌 Specify a proxy server via CLI argument
python download_release.py --proxy http://127.0.0.1:7890
```

### 🔧 Proxy via environment variable

**🪟 PowerShell:**
```powershell
# 🪟 Set proxy environment variables in PowerShell
$env:HTTP_PROXY="http://127.0.0.1:7890"
$env:HTTPS_PROXY="http://127.0.0.1:7890"
python download_release.py
```

**🐧 Bash / zsh / Git Bash:**
```bash
# 🐧 Set proxy environment variables in Bash
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
python download_release.py
```

### 📁 Custom download path (CLI arg, highest priority)

```bash
# 📂 Specify a custom download directory
python download_release.py --path D:\downloads
# python download_release.py --proxy http://127.0.0.1:7890 --path X:\packs\dart-flutter-demo-showcase
```

### ⌨️ Custom download path (interactive, default = current dir)

```bash
# 💬 Run and enter path interactively
python download_release.py
Download path [C:\Users\you]: D:\downloads
```

### 📋 List assets only (no download)

```bash
# 🔍 Preview all release assets without downloading
python download_release.py --list-only
```

## 🏆 Proxy priority

1. 🌐 `--proxy` CLI argument (highest)
2. 🔧 `HTTP_PROXY` / `HTTPS_PROXY` env var
3. ❌ No proxy (default)

## 📂 Output directory

📁 Assets are saved under `scripts/download/<tag>/`:

```
📂 scripts/download/
├── 📜 download_release.py
├── 📖 README.md
├── 🏷️ v0.4.1-alpha.1/
│   ├── 🤖 dart-flutter-demo-android-arm64-*.apk
│   ├── 🤖 dart-flutter-demo-android-universal-*.apk
│   ├── 🤖 dart-flutter-demo-android-universal-profile-*.apk
│   ├── 🤖 dart-flutter-demo-android-x86_64-*.apk
│   ├── 🍎 dart-flutter-demo-ios-arm64-*.ipa
│   ├── 🐧 dart-flutter-demo-linux-x64-*.AppImage
│   ├── 🐧 dart-flutter-demo-linux-x64-*.deb
│   ├── 🐧 dart-flutter-demo-linux-x64-*.tar.gz
│   ├── 🐧 dart-flutter-demo-linux-x64-profile-*.tar.gz
│   ├── 🍎 dart-flutter-demo-macos-arm64-*.dmg
│   ├── 🍎 dart-flutter-demo-macos-arm64-*.zip
│   ├── 🍎 dart-flutter-demo-macos-x64-*.dmg
│   ├── 🍎 dart-flutter-demo-macos-x64-*.zip
│   ├── 🪟 dart-flutter-demo-windows-x64-*-setup.exe
│   ├── 🪟 dart-flutter-demo-windows-x64-profile-*.zip
│   └── 🪟 dart-flutter-demo-windows-x64-*.zip
└── 🏷️ v0.4.0/
    └── ...
```
