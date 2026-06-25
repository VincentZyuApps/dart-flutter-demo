> **[ English](README.md)**
> **[ 简体中文(大陆)](README.zh-cn.md)**

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo)
[![Gitee](https://img.shields.io/badge/Gitee-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/vincent-zyu/dart-flutter-demo)

![dart-flutter-demo](https://socialify.git.ci/VincentZyuApps/dart-flutter-demo/image?description=1&font=Bitter&forks=1&issues=1&language=1&logo=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2Fthumb%2F7%2F79%2FFlutter_logo.svg%2F120px-Flutter_logo.svg.png%3Futm_source%3Dcommons.wikimedia.org%26utm_campaign%3Dindex%26utm_content%3Dthumbnail%26_%3D20230821075714&name=1&owner=1&pulls=1&stargazers=1&theme=Auto)
![onefetch](doc/preview-pics/onefetch.png)

# ✨ dart_flutter_demo

一个跨平台的 Flutter UI 展示 PoC（Proof of Concept）应用，可以跑在 Android、Windows、Linux、macOS 和 iOS 上，使用 GitHub Actions CI 打包工作流构建。

[![Last Commit](https://img.shields.io/github/last-commit/VincentZyuApps/dart-flutter-demo?style=for-the-badge&logo=github&color=181717&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/commits/main/)
[![Build](https://img.shields.io/github/actions/workflow/status/VincentZyuApps/dart-flutter-demo/build.yml?style=for-the-badge&logo=githubactions&logoColor=white&label=Build)](https://github.com/VincentZyuApps/dart-flutter-demo/actions)

<p align="center">
  <img src="assets/images/logo-icon-favicon.png" alt="dart_flutter_demo logo" width="280"/>
</p>

[![Windows x64](https://img.shields.io/static/v1?label=Windows&message=x64&color=0078D4&style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![Linux x64 | ARM64](https://img.shields.io/badge/Linux-x64_|_ARM64-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![macOS x64 | ARM64](https://img.shields.io/badge/macOS-x64_|_ARM64-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)

[![Android x86_64 | ARM64](https://img.shields.io/badge/Android-x86_64_|_ARM64-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![iOS ARM64](https://img.shields.io/badge/iOS-ARM64-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)

## 📊🧬 语言占比

这两张动画图分别按仓库中已跟踪的代码、脚本、文档与构建配置的字节数和行数做分布统计。<br>
![lang-byte-stats](doc/lang-byte-stats.svg)
![lang-line-stats](doc/lang-line-stats.svg)

## 💬🪟 对话框

### 🖼️ 桌面图标

<div align="center">
<table>
  <thead>
    <tr>
      <th align="center">桌面图标预览</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center"><img src="doc/preview-pics/desktop-icon.dock-taskbar-button.windows11.png" width="100%"/><br><sub>Windows 11 dock / 任务栏</sub></td>
    </tr>
    <tr>
      <td align="center"><img src="doc/preview-pics/desktop-icon.start-menu.debian13.kde.png" width="100%"/><br><sub>Debian 13 KDE 开始菜单</sub></td>
    </tr>
    <tr>
      <td align="center"><img src="doc/preview-pics/desktop-icon-widget.android14.png" width="100%"/><br><sub>Android 14 桌面小组件</sub></td>
    </tr>
    <tr>
      <td align="center"><img src="doc/preview-pics/desktop-icon.altserver.self-sign.sideloaded.ios17.png" width="100%"/><br><sub>iOS 17 侧载</sub></td>
    </tr>
  </tbody>
</table>
</div>

### ℹ️ 关于

显示应用名称、版本号、构建号、发布方及相关链接的应用信息对话框。从 AppBar 菜单中打开。<br>
![about](doc/preview-pics/side1.about.png)

### 📘 入门引导

一步步指引展示应用的下载渠道、构建选项及推荐的开发环境配置的引导对话框。从 AppBar 菜单中打开。<br>
![guide](doc/preview-pics/side1.guide.png)

## 🧩📱 页面介绍

### 0. 🖥️ 系统信息实验室

通过原生 C++（Windows）、Kotlin（Android）、Swift（iOS）以及 dart:io fallback 获取系统信息。展示 OS、主机名、内核、运行时间、CPU、内存、磁盘和本地 IP。内置调试链路查看、复制与导出能力，便于诊断采集过程。<br>
源码： [lib/pages/page0_system_info.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page0_system_info.dart)

<div align="center">
<table>
  <thead>
    <tr>
      <th align="center">Dart + Flutter Demo（系统信息页面）</th>
      <th align="center">平台系统信息 (fastfetch)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center"><sub>Windows 11</sub><br><img src="doc/preview-pics/page0.windows11.png" width="100%"/></td>
      <td align="center"><sub>Windows 11</sub><br><img src="doc/preview-pics/fastfetch.windows11.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Windows 10 WSL Arch Linux</sub><br><img src="doc/preview-pics/page0.windows10.wsl.arch-linux.png" width="100%"/></td>
      <td align="center"><sub>Windows 10 WSL Arch Linux</sub><br><img src="doc/preview-pics/fastfetch.windows10.wsl.arch-linux.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Ubuntu 24.04 LXQt</sub><br><img src="doc/preview-pics/page0.ubuntu24.lxqt.png" width="100%"/></td>
      <td align="center"><sub>Ubuntu 24.04 LXQt</sub><br><img src="doc/preview-pics/fastfetch.ubuntu24.lxqt.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Debian 13 KDE</sub><br><img src="doc/preview-pics/page0.debian13.kde.png" width="100%"/></td>
      <td align="center"><sub>Debian 13 KDE</sub><br><img src="doc/preview-pics/fastfetch.debian13.kde.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>macOS 14</sub><br><img src="doc/preview-pics/page0.macos14.png" width="100%"/></td>
      <td align="center"><sub>macOS 14</sub><br><img src="doc/preview-pics/fastfetch.macos14.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Android 15</sub><br><img src="doc/preview-pics/page0.android14.png" width="100%"/></td>
      <td align="center"><sub>Android 15</sub><br><img src="doc/preview-pics/fastfetch.android14.termux.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>iOS 17 (iPad Air 5)</sub><br><img src="doc/preview-pics/page0.ios17.png" width="100%"/></td>
      <td align="center"><sub>iOS 17 (iSH)</sub><br><img src="doc/preview-pics/fastfetch.ios17.iSH.png" width="100%"/></td>
    </tr>
  </tbody>
</table>
</div>

### 1. 💬 对话框实验室

一个同时包含现代 Flutter 对话框与经典 Win32 风格对话框复刻的紧凑实验页。使用复古边框、内凹输入框样式和更大的操作按钮，展示 Flutter 可以在同一个应用里还原非常不同的交互与视觉语言。<br>
源码： [lib/pages/page1_dialog_lab.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page1_dialog_lab.dart)
![page1](doc/preview-pics/page1.dialog.png)

### 2. 🔤 文字排版工作室

一个交互式文字实验场。通过实时控件调整字号、字间距和行高。在系统字体、Google Fonts 和一次性本地字体文件之间切换。包含实时预览文本编辑、深浅色主题自动文字颜色切换、预设色板，以及带 RGB 与 HEX 读数的自定义颜色选择器。<br>
源码： [lib/pages/page2_typography_studio.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page2_typography_studio.dart)
![page2](doc/preview-pics/page2.typograghy.png)

### 3. 🧱 自适应网格

一个由 LayoutBuilder 驱动的响应式 GitHub 仓库浏览页。可从可配置的个人或组织仓库页面抓取数据，支持代理设置、筛选与排序控件、可折叠配置区、Grid / Masonry / List 布局切换，以及从 5 到 1 的目标列数调整。<br>
源码： [lib/pages/page3_adaptive_grid.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page3_adaptive_grid.dart)
![page3](doc/preview-pics/page3.masonry-grid.png)

### 4. 🎛️ 控件与反馈实验室

一个用于交互控件与反馈模式的紧凑实验页。包含单选框、多选框、开关、进度指示器、SnackBar 和 BottomSheet。适合检查状态切换、动效反馈与组件响应性。<br>
源码： [lib/pages/page4_controls_feedback.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page4_controls_feedback.dart)
![page4](doc/preview-pics/page4.controls-schema-feedback.png)

## 📁 文件结构

`lib/` 目录按入口、应用壳、页面、通用组件、服务和模型做了分层：

| 文件 | 作用 |
|---|---|
| `lib/main.dart` | 程序入口，启动 `FlutterShowcaseApp`。 |
| `lib/app.dart` | 应用壳、主题切换、导航、关于/引导弹窗和页面切换。 |
| `lib/models/mock_data.dart` | 演示用随机数据生成工具。 |
| `lib/models/page3_enums.dart` | GitHub 网格页使用的枚举和密度辅助。 |
| `lib/pages/page0_system_info.dart` | 系统信息展示页。 |
| `lib/pages/page1_dialog_lab.dart` | 对话框对比与交互演示页。 |
| `lib/pages/page2_typography_studio.dart` | 字体排版实验页。 |
| `lib/pages/page3_adaptive_grid.dart` | 自适应 GitHub 仓库浏览页。 |
| `lib/pages/page4_controls_feedback.dart` | 控件与反馈组件实验页。 |
| `lib/services/android_home_widget_service.dart` | Android 桌面小组件同步桥接。 |
| `lib/services/app_performance.dart` | FPS 和重建次数统计辅助。 |
| `lib/services/github_repository_service.dart` | GitHub 仓库解析、抓取和数据模型。 |
| `lib/services/system_info_service.dart` | 跨平台系统信息采集、调试快照、复制/导出辅助。 |
| `lib/widgets/animated_page.dart` | 页面切换和层级动画封装。 |
| `lib/widgets/repository_card.dart` | 网格样式的仓库卡片。 |
| `lib/widgets/repository_list_tile.dart` | 列表样式的仓库条目。 |
| `lib/widgets/state_shell.dart` | 通用的空态/加载态/错误态布局。 |
| `lib/widgets/tag.dart` | 小型标签胶囊组件。 |


## ⚙️🚀 CI/CD

GitHub Actions 负责自动构建与打包。提交信息包含 `build action` 或 `build release` 即可触发流水线。详见 [build.zh-cn.md](.github/workflows/build.zh-cn.md)。

## ⚠️🩺 故障排除

- **🪟🐧 Windows / Linux GPU问题**：使用软件渲染启动：`./dart_flutter_demo --disable-gpu`
- **🍎 macOS 虚拟机 图形问题**（VMware、VirtualBox 等）：Flutter 桌面应用依赖 Apple Metal，虚拟机无法提供 Metal 支持，因此无法运行。请使用物理 Mac 或 [GitHub Actions macOS runners](https://github.com/VincentZyuApps/mac-test-action-runner)。
- **🤖 Android APK**：未使用固定 keystore 签名。每次 release 使用不同的 debug key，安装新版本前需要**先卸载旧版本**以避免签名冲突。
- **📱 iOS IPA**：CI 未配置代码签名，想在自己设备上运行需要自行签名。<br>*(仅供参考 — 测试设备 iPad Air 5，iOS 17；其他设备/系统版本可能有差异)*：
  1. 在 Windows 或 macOS 上下载并安装 [AltStore](https://altstore.io)，打开 AltServer（系统托盘）
  2. iPad 用 USB 连电脑 → 托盘图标 → Install AltStore → 选择你的 iPad
  3. 输入 Apple ID（仅用于签名，不会存储）
  4. iPad 上：**设置 → 通用 → VPN 与设备管理 → 信任你的 Apple ID 证书**
   5. 打开 AltStore → 点 **+** → 选择 `.ipa` 文件
   6. 确保**关掉所有代理软件 / VPN**（如 Shadowrocket、Clash 等），然后打开 app
   7. 免费账号每 **7 天**需要刷新签名（AltStore 会自动提示，电脑保持 AltServer 运行或 iPad 与电脑同 WiFi）

## 📦 依赖项

| 依赖项 | Badge |
|---|---|
| Flutter | [![flutter](https://img.shields.io/badge/Flutter-stable-02569B.svg?logo=flutter)](https://flutter.dev/) |
| Flutter Localizations | [![flutter_localizations](https://img.shields.io/badge/Flutter%20Localizations-sdk-02569B.svg?logo=flutter)](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization) |
| Intl | [![intl](https://img.shields.io/badge/intl-any-0175C2.svg?logo=dart)](https://pub.dev/packages/intl) |
| File Selector | [![file_selector](https://img.shields.io/badge/file__selector-%5E1.1.0-00A884.svg?logo=flutter)](https://pub.dev/packages/file_selector) |
| Google Fonts | [![google_fonts](https://img.shields.io/badge/Google%20Fonts-%5E6.1.0-4285F4.svg?logo=googlefonts)](https://pub.dev/packages/google_fonts) |
| Flutter Colorpicker | [![flutter_colorpicker](https://img.shields.io/badge/flutter__colorpicker-%5E1.1.0-6750A4.svg?logo=flutter)](https://github.com/mchome/flutter_colorpicker) |
| Package Info Plus | [![package_info_plus](https://img.shields.io/badge/package__info__plus-%5E8.0.2-FF6F00.svg?logo=dart)](https://pub.dev/packages/package_info_plus) |
| URL Launcher | [![url_launcher](https://img.shields.io/badge/url__launcher-%5E6.3.1-1E88E5.svg?logo=linktree)](https://pub.dev/packages/url_launcher) |
| Testing | [![Flutter Test](https://img.shields.io/badge/Flutter%20Test-sdk-00A884.svg?logo=flutter)](https://docs.flutter.dev/testing) |
| Linting | [![Flutter Lints](https://img.shields.io/badge/flutter__lints-%5E5.0.0-9B59B6.svg?logo=dart)](https://pub.dev/packages/flutter_lints) |

## 🛠️ 技术栈

| 技术 | Badge |
|---|---|
| Language | [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev/) |
| Design | [![Material 3](https://img.shields.io/badge/Material%203-design%20system-6750A4.svg?logo=materialdesign)](https://m3.material.io/) |
| Windows | [![Windows](https://img.shields.io/static/v1?label=Windows&message=supported&color=0078D4&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://docs.flutter.dev/platform-integration/desktop) |
| Linux | [![Linux](https://img.shields.io/badge/Linux-supported-f84e29.svg?logo=linux)](https://docs.flutter.dev/platform-integration/linux) |
| macOS | [![macOS](https://img.shields.io/badge/macOS-supported-8E8E93.svg?logo=apple)](https://docs.flutter.dev/platform-integration/macos) |
| Android | [![Android](https://img.shields.io/badge/Android-supported-3DDC84.svg?logo=android)](https://docs.flutter.dev/platform-integration/android) |
| iOS | [![iOS](https://img.shields.io/badge/iOS-supported-000000.svg?logo=apple)](https://docs.flutter.dev/platform-integration/ios) |
| Min SDK | [![SDK](https://img.shields.io/badge/SDK-%3E%3D3.0.0-02569B.svg?logo=dart)](https://dart.dev/tools/pub/pubspec) |

## 🏷️ 其他Badge

| Badge | Link |
|---|---|
| Version | [![Version](https://img.shields.io/badge/Version-0.4.1--alpha.1-02569B.svg?logo=flutter&labelColor=181717)](https://github.com/VincentZyuApps/dart-flutter-demo/releases) |
| Stars | [![Stars](https://img.shields.io/github/stars/VincentZyuApps/dart-flutter-demo?style=flat&logo=github&label=stars&labelColor=181717&color=FFD700)](https://github.com/VincentZyuApps/dart-flutter-demo/stargazers) |
| Last Commit | [![Last Commit](https://img.shields.io/github/last-commit/VincentZyuApps/dart-flutter-demo?logo=github&label=last%20commit&labelColor=181717&color=02569B)](https://github.com/VincentZyuApps/dart-flutter-demo/commits/main/) |
| Github Action CI/CD | [![release](https://img.shields.io/github/v/release/VincentZyuApps/dart-flutter-demo?logo=github&label=发布&color=02569B&labelColor=181717)](https://github.com/VincentZyuApps/dart-flutter-demo/releases) · [![build](https://img.shields.io/github/actions/workflow/status/VincentZyuApps/dart-flutter-demo/build.yml?branch=main&logo=githubactions&label=构建)](https://github.com/VincentZyuApps/dart-flutter-demo/actions) |
