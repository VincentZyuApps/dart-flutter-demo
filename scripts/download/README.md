# 📥 发行包下载工具

⬇️ 通过简单的交互式命令行工具下载指定 GitHub Release 中的全部附件。
🧩 不依赖第三方软件包，只使用 Python 标准库。
📦 确认下载前会显示所选 Release 的附件数量与总下载大小。

## 🚀 使用方法

### ⚡ 不使用代理（默认）

```bash
# 💻 使用默认设置运行，不使用代理
python download-release.py
```

### 🌐 通过 `--proxy` 参数设置代理（优先级最高）

```bash
# 🔌 通过命令行参数指定代理服务器
python download-release.py --proxy http://127.0.0.1:7890
```

### 🔧 通过环境变量设置代理

**🪟 PowerShell：**
```powershell
# 🪟 在 PowerShell 中设置代理环境变量
$env:HTTP_PROXY="http://127.0.0.1:7890"
$env:HTTPS_PROXY="http://127.0.0.1:7890"
python download-release.py
```

**🐧 Bash、zsh 或 Git Bash：**
```bash
# 🐧 在 Bash 中设置代理环境变量
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
python download-release.py
```

### 📁 通过命令行参数指定下载目录（优先级最高）

```bash
# 📂 指定自定义下载目录
python download-release.py --path D:\downloads
# python download-release.py --proxy http://127.0.0.1:7890 --path X:\packs\dart-flutter-demo-showcase
```

### ⌨️ 交互式指定下载目录（默认使用当前目录）

```bash
# 💬 运行后根据提示输入目录
python download-release.py
Download path [C:\Users\you]: D:\downloads
```

上面的 `Download path` 是工具当前输出的交互提示，输入冒号后面的目标目录即可。

### 📋 只列出附件，不执行下载

```bash
# 🔍 预览 Release 中的全部附件
python download-release.py --list-only
```

## 🏆 代理优先级

1. 🌐 `--proxy` 命令行参数（优先级最高）
2. 🔧 `HTTP_PROXY` 或 `HTTPS_PROXY` 环境变量
3. ❌ 不使用代理（默认）

## 📂 输出目录

📁 下载的附件会保存到 `scripts/download/<tag>/`：

```
📂 scripts/download/
├── 📜 download-release.py
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
