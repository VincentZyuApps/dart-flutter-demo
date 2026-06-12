> **[📖 English](README.md)**
> **[📖 简体中文(大陆)](README.zh-cn.md)**

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo)
[![Gitee](https://img.shields.io/badge/Gitee-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/vincent-zyu/dart-flutter-demo)

![dart-flutter-demo](https://socialify.git.ci/VincentZyuApps/dart-flutter-demo/image?description=1&font=Bitter&forks=1&issues=1&language=1&logo=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2Fthumb%2F7%2F79%2FFlutter_logo.svg%2F120px-Flutter_logo.svg.png%3Futm_source%3Dcommons.wikimedia.org%26utm_campaign%3Dindex%26utm_content%3Dthumbnail%26_%3D20230821075714&name=1&owner=1&pulls=1&stargazers=1&theme=Auto)
![onefetch](doc/preview-pics/onefetch.png)

# ✨ dart_flutter_demo

A cross-platform Flutter UI showcase PoC (Proof of Concept) app, available on Android, Windows, Linux, macOS, and iOS, built by a GitHub Actions CI packaging workflow.

<p align="center">
  <img src="assets/images/logo-icon-favicon.png" alt="dart_flutter_demo logo" width="280"/>
</p>

[![Last Commit](https://img.shields.io/github/last-commit/VincentZyuApps/dart-flutter-demo?style=for-the-badge&logo=github&color=181717&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/commits/main/)
[![Build](https://img.shields.io/github/actions/workflow/status/VincentZyuApps/dart-flutter-demo/build.yml?style=for-the-badge&logo=githubactions&logoColor=white&label=Build)](https://github.com/VincentZyuApps/dart-flutter-demo/actions)

[![Windows x64](https://img.shields.io/static/v1?label=Windows&message=x64&color=0078D4&style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![Linux x64 | ARM64](https://img.shields.io/badge/Linux-x64_|_ARM64-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![macOS x64 | ARM64](https://img.shields.io/badge/macOS-x64_|_ARM64-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)

[![Android x86_64 | ARM64](https://img.shields.io/badge/Android-x86_64_|_ARM64-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![iOS ARM64](https://img.shields.io/badge/iOS-ARM64-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)

## 📊🧬 Language Footprint

Animated breakdowns of tracked code, script, doc, and build-config size by bytes and by lines.<br>
![lang-byte-stats](doc/lang-byte-stats.svg)
![lang-line-stats](doc/lang-line-stats.svg)

## 💬🪟 Dialogs

### ℹ️ About

An app information dialog that displays app name, version, build number, publisher, and related links. Accessible from the AppBar menu.<br>
![about](doc/preview-pics/side1.about.png)

### 📘 Getting Started Guide

A step-by-step walkthrough dialog showing the app's download channels, build options, and recommended development setup. Accessible from the AppBar menu.<br>
![guide](doc/preview-pics/side1.guide.png)

## 🧩📱 Pages

### 0. 🖥️ System Info

Displays system information through native C++ (Windows), Kotlin (Android), Swift (iOS), and dart:io fallbacks. Shows OS, hostname, kernel, uptime, CPU, memory, disk, and local IP. Includes built-in debug trace viewing plus copy/export actions for diagnostics.<br>
Source: [lib/pages/page0_system_info.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page0_system_info.dart)

<div align="center">
<table>
  <thead>
    <tr>
      <th align="center">Dart + Flutter Demo (System Info Page)</th>
      <th align="center">Platform System Info (fastfetch)</th>
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

### 1. 💬 Dialog Lab

A compact dialog lab with both a modern Flutter dialog and a classic Win32-style dialog recreation. Uses retro borders, inset input styling, and larger action buttons to demonstrate that Flutter can reproduce very different interaction and visual languages in one app.<br>
Source: [lib/pages/page1_dialog_lab.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page1_dialog_lab.dart)
![page1](doc/preview-pics/page1.dialog.png)

### 2. 🔤 Typography Studio

An interactive text playground. Adjust font size, letter spacing, and line height with live controls. Switch between the system font, Google Fonts, and a one-shot local font file. Includes live preview text editing, dark/light auto text color switching, preset swatches, and a custom color picker with RGB and HEX readout.<br>
Source: [lib/pages/page2_typography_studio.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page2_typography_studio.dart)
![page2](doc/preview-pics/page2.typograghy.png)

### 3. 🧱 Adaptive Grid

A responsive GitHub repository browser driven by LayoutBuilder. Fetches repositories from configurable personal or organization repository pages, supports proxy configuration, filter and sort controls, collapsible configuration UI, layout switching between Grid / Masonry / List, and adjustable target columns from 5 to 1.<br>
Source: [lib/pages/page3_adaptive_grid.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page3_adaptive_grid.dart)
![page3](doc/preview-pics/page3.masonry-grid.png)

### 4. 🎛️ Controls & Feedback

A compact lab for interactive controls and user feedback. Includes radios, checkboxes, switches, progress indicators, snack bars, and bottom sheets. Useful for checking state transitions, motion, and component responsiveness.<br>
Source: [lib/pages/page4_controls_feedback.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page4_controls_feedback.dart)
![page4](doc/preview-pics/page4.controls-schema-feedback.png)


## ⚙️🚀 CI/CD

GitHub Actions handles automated builds and packaging. Push a commit containing `build action` or `build release` to trigger the pipeline. See [build.md](.github/workflows/build.md) for details.

## ⚠️🩺 Troubleshooting

- **🪟🐧 Windows / Linux GPU issues**: Launch with software rendering: `./dart_flutter_demo --disable-gpu`
- **🍎 macOS virtual machines graphic issues** (VMware, VirtualBox, etc.): Flutter desktop apps require Apple Metal, which is unavailable in VMs. Use a physical Mac or [GitHub Actions macOS runners](https://github.com/VincentZyuApps/mac-test-action-runner) instead.
- **🤖 Android APK**: Not signed with a persistent keystore. Each release uses a different debug key, so you must **uninstall the old version** before installing a new one to avoid signature conflicts.
- **📱 iOS IPA**: CI does not configure code signing. To run on your own device, self-sign the `.ipa` before installing.<br>*(for reference — tested on iPad Air 5, iOS 17; other devices/versions may vary)*:
  1. Download and install [AltStore](https://altstore.io) on Windows or macOS, open AltServer (system tray)
  2. Connect iPad via USB → tray icon → Install AltStore → select your iPad
  3. Enter your Apple ID (used only for signing, not stored)
  4. On iPad: **Settings → General → VPN & Device Management → trust your Apple ID certificate**
  5. Open AltStore → **+** → select the `.ipa` file
  6. Free accounts need **re-signing every 7 days** (AltStore prompts automatically; keep AltServer running on your PC/iPad on same WiFi)

## 📦 Dependencies

| Dependencies | Badge |
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

## 🛠️ Tech Stack

| Tech | Badge |
|---|---|
| Language | [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev/) |
| Design | [![Material 3](https://img.shields.io/badge/Material%203-design%20system-6750A4.svg?logo=materialdesign)](https://m3.material.io/) |
| Windows | [![Windows](https://img.shields.io/static/v1?label=Windows&message=supported&color=0078D4&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://docs.flutter.dev/platform-integration/desktop) |
| Linux | [![Linux](https://img.shields.io/badge/Linux-supported-f84e29.svg?logo=linux)](https://docs.flutter.dev/platform-integration/linux) |
| macOS | [![macOS](https://img.shields.io/badge/macOS-supported-8E8E93.svg?logo=apple)](https://docs.flutter.dev/platform-integration/macos) |
| Android | [![Android](https://img.shields.io/badge/Android-supported-3DDC84.svg?logo=android)](https://docs.flutter.dev/platform-integration/android) |
| iOS | [![iOS](https://img.shields.io/badge/iOS-supported-000000.svg?logo=apple)](https://docs.flutter.dev/platform-integration/ios) |
| Min SDK | [![SDK](https://img.shields.io/badge/SDK-%3E%3D3.0.0-02569B.svg?logo=dart)](https://dart.dev/tools/pub/pubspec) |

## 🏷️ Other Badge

| Badge | Link |
|---|---|
| Version | [![Version](https://img.shields.io/badge/Version-0.4.1--alpha.1-02569B.svg?logo=flutter&labelColor=181717)](https://github.com/VincentZyuApps/dart-flutter-demo/releases) |
| Stars | [![Stars](https://img.shields.io/github/stars/VincentZyuApps/dart-flutter-demo?style=flat&logo=github&label=stars&labelColor=181717&color=FFD700)](https://github.com/VincentZyuApps/dart-flutter-demo/stargazers) |
| Last Commit | [![Last Commit](https://img.shields.io/github/last-commit/VincentZyuApps/dart-flutter-demo?logo=github&label=last%20commit&labelColor=181717&color=02569B)](https://github.com/VincentZyuApps/dart-flutter-demo/commits/main/) |
| Github Action CI/CD | [![release](https://img.shields.io/github/v/release/VincentZyuApps/dart-flutter-demo?logo=github&label=release&color=02569B&labelColor=181717)](https://github.com/VincentZyuApps/dart-flutter-demo/releases) · [![build](https://img.shields.io/github/actions/workflow/status/VincentZyuApps/dart-flutter-demo/build.yml?branch=main&logo=githubactions&label=build)](https://github.com/VincentZyuApps/dart-flutter-demo/actions) |
