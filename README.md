> **[【📖 English README doc】](README.md)**
> **[【📖 简体中文 README 文档】](README.zh-cn.md)**
>
> **[【🔐 English privacy】](PRIVACY.md)**
> **[【🔐 简体中文隐私条款】](PRIVACY.zh-cn.md)**

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo)
[![Gitee](https://img.shields.io/badge/Gitee-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/vincent-zyu/dart-flutter-demo)

![dart-flutter-demo](https://socialify.git.ci/VincentZyuApps/dart-flutter-demo/image?description=1&font=Bitter&forks=1&issues=1&language=1&logo=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2Fthumb%2F7%2F79%2FFlutter_logo.svg%2F120px-Flutter_logo.svg.png%3Futm_source%3Dcommons.wikimedia.org%26utm_campaign%3Dindex%26utm_content%3Dthumbnail%26_%3D20230821075714&name=1&owner=1&pulls=1&stargazers=1&theme=Auto)
![onefetch](doc/images/preview/onefetch.png)

# ✨ dart_flutter_demo

A cross-platform Flutter UI showcase PoC (Proof of Concept) app, available on Android, Windows, Linux, macOS, and iOS, built by a GitHub Actions CI packaging workflow.

[![Last Commit](https://img.shields.io/github/last-commit/VincentZyuApps/dart-flutter-demo?style=for-the-badge&logo=github&color=181717&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/commits/main/)
[![Release & Publish](https://img.shields.io/github/actions/workflow/status/VincentZyuApps/dart-flutter-demo/release-publish.yml?style=for-the-badge&logo=githubactions&logoColor=white&label=Release%20%26%20Publish)](https://github.com/VincentZyuApps/dart-flutter-demo/actions)

<p align="center">
  <img src="assets/images/logo-icon-favicon.png" alt="dart_flutter_demo logo" width="280"/>
</p>

[![Windows x64](https://img.shields.io/static/v1?label=Windows&message=x64&color=0078D4&style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![Linux x64](https://img.shields.io/badge/Linux-x64-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![macOS x64 | ARM64](https://img.shields.io/badge/macOS-x64_|_ARM64-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)

[![Android x86_64 | ARM64](https://img.shields.io/badge/Android-x86_64_|_ARM64-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)
[![iOS ARM64](https://img.shields.io/badge/iOS-ARM64-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/VincentZyuApps/dart-flutter-demo/releases)

## 📊🧬 Language Footprint

Animated breakdowns of tracked code, script, doc, and build-config size by bytes and by lines.<br>
![lang-byte-stats](doc/images/svg/lang-byte-stats.svg)
![lang-line-stats](doc/images/svg/lang-line-stats.svg)

## 💬🪟 Dialogs

### 🖼️ Desktop Icons

<div align="center">
<table>
  <thead>
    <tr>
      <th align="center">Desktop Icon Preview</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center"><img src="doc/images/preview/desktop-icon.start-menu.dock-taskbar-button.windows11.png" width="100%"/><br><sub>Windows 11 dock / taskbar</sub></td>
    </tr>
    <tr>
      <td align="center"><img src="doc/images/preview/desktop-icon.start-menu.debian13.kde.png" width="100%"/><br><sub>Debian 13 KDE start menu</sub></td>
    </tr>
    <tr>
      <td align="center"><img src="doc/images/preview/desktop-icon-widget.android14.png" width="100%"/><br><sub>Android 14 widget</sub></td>
    </tr>
    <tr>
      <td align="center"><img src="doc/images/preview/desktop-icon.altserver.self-sign.sideloaded.ios17.png" width="100%"/><br><sub>iOS 17 sideloaded</sub></td>
    </tr>
  </tbody>
</table>
</div>

### ℹ️ About

An app information dialog that displays app name, version, build number, publisher, and related links. Accessible from the AppBar menu.<br>
![about](doc/images/preview/side1.about.png)

### 📘 Getting Started Guide

A step-by-step walkthrough dialog showing the app's download channels, build options, and recommended development setup. Accessible from the AppBar menu.<br>
![guide](doc/images/preview/side1.guide.png)

## 🧩📱 Pages

### 0. 🖥️ System Info

Displays typed system information through the reusable local plugin `system_info_vincentzyu`: Win32 C++ FFI first on Windows, Kotlin/Swift MethodChannels on Android and Apple platforms, and Dart/OS interfaces on Linux. Formatting stays in the App layer. Every field shows its source, elapsed time, and fallback chain. Session logs are mirrored to memory, UI, console, and rotating files (10 MiB each, newest five retained); hostname and local IP are never uploaded automatically, and export requires a privacy confirmation.<br>
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
      <td align="center"><sub>Windows 11</sub><br><img src="doc/images/preview/page0.windows11.png" width="100%"/></td>
      <td align="center"><sub>Windows 11</sub><br><img src="doc/images/preview/fastfetch.windows11.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Windows 10 WSL Arch Linux</sub><br><img src="doc/images/preview/page0.windows10.wsl.arch-linux.png" width="100%"/></td>
      <td align="center"><sub>Windows 10 WSL Arch Linux</sub><br><img src="doc/images/preview/fastfetch.windows10.wsl.arch-linux.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Ubuntu 24.04 LXQt</sub><br><img src="doc/images/preview/page0.ubuntu24.lxqt.png" width="100%"/></td>
      <td align="center"><sub>Ubuntu 24.04 LXQt</sub><br><img src="doc/images/preview/fastfetch.ubuntu24.lxqt.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Debian 13 KDE</sub><br><img src="doc/images/preview/page0.debian13.kde.png" width="100%"/></td>
      <td align="center"><sub>Debian 13 KDE</sub><br><img src="doc/images/preview/fastfetch.debian13.kde.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>macOS 14</sub><br><img src="doc/images/preview/page0.macos14.png" width="100%"/></td>
      <td align="center"><sub>macOS 14</sub><br><img src="doc/images/preview/fastfetch.macos14.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>Android 15</sub><br><img src="doc/images/preview/page0.android14.png" width="100%"/></td>
      <td align="center"><sub>Android 15</sub><br><img src="doc/images/preview/fastfetch.android14.termux.png" width="100%"/></td>
    </tr>
    <tr>
      <td align="center"><sub>iOS 17 (iPad Air 5)</sub><br><img src="doc/images/preview/page0.ios17.png" width="100%"/></td>
      <td align="center"><sub>iOS 17 (iSH)</sub><br><img src="doc/images/preview/fastfetch.ios17.iSH.png" width="100%"/></td>
    </tr>
  </tbody>
</table>
</div>

### 1. 💬 Dialog Lab

A compact dialog lab with both a modern Flutter dialog and a classic Win32-style dialog recreation. Uses retro borders, inset input styling, and larger action buttons to demonstrate that Flutter can reproduce very different interaction and visual languages in one app.<br>
Source: [lib/pages/page1_dialog_lab.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page1_dialog_lab.dart)
![page1](doc/images/preview/page1.dialog.png)

### 2. 🔤 Typography Studio

An interactive text playground. Adjust font size, letter spacing, and line height with live controls. Switch between the system font, Google Fonts, and a one-shot local font file. Includes live preview text editing, dark/light auto text color switching, preset swatches, and a custom color picker with RGB and HEX readout.<br>
Source: [lib/pages/page2_typography_studio.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page2_typography_studio.dart)
![page2](doc/images/preview/page2.typograghy.png)

### 3. 🧱 Adaptive Grid

A responsive GitHub repository browser driven by LayoutBuilder. Fetches repositories from configurable personal or organization repository pages, supports proxy configuration, filter and sort controls, collapsible configuration UI, layout switching between Grid / Masonry / List, and adjustable target columns from 5 to 1.<br>
Source: [lib/pages/page3_adaptive_grid.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page3_adaptive_grid.dart)
![page3](doc/images/preview/page3.masonry-grid.png)

### 4. 🎛️ Controls & Feedback

A responsive control-state and accessibility lab. It combines radios, checkboxes (including an indeterminate state), switches, validation and loading states, text scaling, high-contrast previews, focus diagnostics, and live JSON state inspection. Its async task can run, pause, resume, fail, retry, cancel, or complete, with determinate and indeterminate progress plus SnackBar, dialog, banner, and bottom-sheet feedback.<br>
Source: [lib/pages/page4_controls_feedback.dart](https://github.com/VincentZyu233/dart-flutter-demo/blob/main/lib/pages/page4_controls_feedback.dart)
![page4](doc/images/preview/page4.controls-schema-feedback.png)

## 📁 File Structure

The app keeps all five platform projects in source control. Reusable system-information code lives in a local Flutter plugin:

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point; boots `FlutterShowcaseApp`. |
| `lib/app.dart` | App shell, theme switching, navigation, about/guide dialogs, and page switching. |
| `lib/models/mock_data.dart` | Small random-data helpers for demo content. |
| `lib/models/page3_enums.dart` | Enums and density helpers used by the GitHub grid page. |
| `lib/pages/page0_system_info.dart` | System info showcase page. |
| `lib/pages/page1_dialog_lab.dart` | Dialog comparison and interaction demo page. |
| `lib/pages/page2_typography_studio.dart` | Typography playground page. |
| `lib/pages/page3_adaptive_grid.dart` | Adaptive GitHub repository browser page. |
| `lib/pages/page4_controls_feedback.dart` | Controls and feedback component lab. |
| `lib/services/android_home_widget_service.dart` | Android home-widget sync bridge. |
| `lib/services/app_performance.dart` | FPS tracking and rebuild count helpers. |
| `lib/services/github_repository_service.dart` | GitHub repository parsing, fetching, and data models. |
| `lib/services/system_info_service.dart` | App formatting, logging setup, debug snapshot, and copy/export adapter. |
| `lib/widgets/animated_page.dart` | Page transitions and staggered animation wrappers. |
| `lib/widgets/repository_card.dart` | Grid-style repository card widget. |
| `lib/widgets/repository_list_tile.dart` | List-style repository row widget. |
| `lib/widgets/state_shell.dart` | Shared empty/loading/error state layout. |
| `lib/widgets/tag.dart` | Small pill/tag display widget. |
| `packages/system_info_vincentzyu/` | Reusable typed system-information plugin for all five platforms. |
| `android/`, `ios/`, `windows/`, `linux/`, `macos/` | Committed Flutter platform projects; normal CI never regenerates them. |
| `.github/workflows/profile-debug.yml` | Seven-day Windows/Linux/Android Profile and Debug artifacts. |
| `.github/workflows/performance.yml` | Seven-day or permanent Pre-release desktop Profile build reports. |


## 🧪 Build Modes

| Mode | GitHub output | JIT | AOT | Optimized | Debug symbols | Typical use |
|:-----|:--------------|:---:|:---:|:---------:|:-------------:|:------------|
| **Debug** | 7-day Actions artifacts | ✅ | ❌ | ❌ | ✅ | Development and diagnostics |
| **Profile** | Permanent Release assets plus 7-day developer artifacts | ❌ | ✅ | ✅ | Limited | Performance profiling on real devices or hosts |
| **🚀 Release** | Permanent GitHub Release assets | ❌ | ✅ | ✅ | ❌ | Production-style use |

> Release assets use `flutter build <platform> --release`. This repository runs Flutter analysis, tests, builds, and profiling through GitHub Actions rather than the local Flutter SDK.

## ⚙️🚀 CI/CD

GitHub Actions uses exact, case-sensitive hyphenated tokens: `[build-release]` publishes an app Release with a verified x86_64 `.flatpak`; `[build-publish]` additionally requests a signed `stable` update through the self-hosted [Flatpak repository](https://vincentzyuapps.github.io/flatpak-repo/) and submits the MSIX to Microsoft Store certification; `[build-profile]` and `[build-debug]` create seven-day developer artifacts; `[run-performance]` keeps performance reports for seven days; `[release-performance]` creates a permanent Performance Pre-release. Brackets are commit-style punctuation, while CI matches the token itself. See [ci.md](.github/workflows/ci.md) for manual options and platform bootstrap details.

## Platform Baselines

| Platform | Declared baseline | Current release architecture |
|---|---|---|
| Windows | Windows 10 or newer | x64 |
| Linux | Modern x64 desktop distribution with GTK 3 | x64 |
| macOS | macOS 10.15 or newer | x64 and ARM64 |
| Android | API 21 or newer | Universal, x86_64, and ARM64 |
| iOS / iPadOS | iOS 13.0 or newer | ARM64 unsigned IPA |

Every Windows artifact, including the Microsoft Store submission MSIX, is x64-only. The unsigned MSIX is intended for Partner Center submission; use the EXE or portable ZIP for normal GitHub downloads.

The iOS baseline is the configured build minimum, not a claim that every OS/device combination has been tested. The current known physical-device result is iPad Air 5 on iOS 17.

## ⚠️🩺 Troubleshooting

- **🪟🐧 Windows / Linux GPU issues**: Launch with software rendering: `./dart_flutter_demo --disable-gpu`
- **🍎 macOS security prompt**: If macOS blocks the app because Apple cannot verify it, open **System Settings → Privacy & Security**, scroll down to **Security**, then click **Open Anyway** for `dart_flutter_demo`.
- **🍎 macOS virtual machines graphic issues** (VMware, VirtualBox, etc.): Flutter desktop apps require Apple Metal, which is unavailable in VMs. Use a physical Mac or [GitHub Actions macOS runners](https://github.com/VincentZyuApps/mac-test-action-runner) instead.
- **🤖 Android APK**: Not signed with a persistent keystore. Each release uses a different debug key, so you must **uninstall the old version** before installing a new one to avoid signature conflicts.
- **📱 iOS IPA**: CI does not configure code signing. To run on your own device, self-sign the `.ipa` before installing.<br>*(for reference — tested on iPad Air 5, iOS 17; other devices/versions may vary)*:
  1. Download and install [AltStore](https://altstore.io) on Windows or macOS, open AltServer (system tray)
  2. Connect iPad via USB → tray icon → Install AltStore → select your iPad
  3. Enter your Apple ID (used only for signing, not stored)
  4. On iPad: **Settings → General → VPN & Device Management → trust your Apple ID certificate**
   5. Open AltStore → **+** → select the `.ipa` file
   6. Make sure to **turn off any proxy / VPN software** (e.g. Shadowrocket, Clash, etc.), then open the app
   7. Free accounts need **re-signing every 7 days** (AltStore prompts automatically; keep AltServer running on your PC/iPad on same WiFi)

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
| Path Provider | [![path_provider](https://img.shields.io/badge/path__provider-%5E2.1.5-02569B.svg?logo=flutter)](https://pub.dev/packages/path_provider) |
| System Info VincentZyu | [![system_info_vincentzyu](https://img.shields.io/badge/system__info__vincentzyu-local-02569B.svg?logo=dart)](https://github.com/VincentZyuApps/dart-flutter-demo/tree/main/packages/system_info_vincentzyu) |
| URL Launcher | [![url_launcher](https://img.shields.io/badge/url__launcher-%5E6.3.1-1E88E5.svg?logo=linktree)](https://pub.dev/packages/url_launcher) |
| Testing | [![Flutter Test](https://img.shields.io/badge/Flutter%20Test-sdk-00A884.svg?logo=flutter)](https://docs.flutter.dev/testing) |
| Linting | [![Flutter Lints](https://img.shields.io/badge/flutter__lints-%5E5.0.0-9B59B6.svg?logo=dart)](https://pub.dev/packages/flutter_lints) |

## 🛠️ Tech Stack

| Tech | Badge |
|---|---|
| Language | [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev/) |
| Min SDK | [![SDK](https://img.shields.io/badge/SDK-%3E%3D3.0.0-02569B.svg?logo=dart)](https://dart.dev/tools/pub/pubspec) |
| Design | [![Material 3](https://img.shields.io/badge/Material%203-design%20system-6750A4.svg?logo=materialdesign)](https://m3.material.io/) |
| Windows | [![Windows](https://img.shields.io/static/v1?label=Windows&message=supported&color=0078D4&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://docs.flutter.dev/platform-integration/desktop) |
| Linux | [![Linux](https://img.shields.io/badge/Linux-supported-f84e29.svg?logo=linux)](https://docs.flutter.dev/platform-integration/linux) |
| macOS | [![macOS](https://img.shields.io/badge/macOS-supported-8E8E93.svg?logo=apple)](https://docs.flutter.dev/platform-integration/macos) |
| Android | [![Android](https://img.shields.io/badge/Android-supported-3DDC84.svg?logo=android)](https://docs.flutter.dev/platform-integration/android) |
| iOS | [![iOS](https://img.shields.io/badge/iOS-supported-000000.svg?logo=apple)](https://docs.flutter.dev/platform-integration/ios) |

## 🏷️ Other Badge

| Badge | Link |
|---|---|
| Version | [![Version](https://img.shields.io/badge/Version-0.4.1--alpha.1-02569B.svg?logo=flutter&labelColor=181717)](https://github.com/VincentZyuApps/dart-flutter-demo/releases) |
| Stars | [![Stars](https://img.shields.io/github/stars/VincentZyuApps/dart-flutter-demo?style=flat&logo=github&label=stars&labelColor=181717&color=FFD700)](https://github.com/VincentZyuApps/dart-flutter-demo/stargazers) |
| Last Commit | [![Last Commit](https://img.shields.io/github/last-commit/VincentZyuApps/dart-flutter-demo?logo=github&label=last%20commit&labelColor=181717&color=02569B)](https://github.com/VincentZyuApps/dart-flutter-demo/commits/main/) |
| Github Action CI/CD | [![release](https://img.shields.io/github/v/release/VincentZyuApps/dart-flutter-demo?logo=github&label=release&color=02569B&labelColor=181717)](https://github.com/VincentZyuApps/dart-flutter-demo/releases) · [![build](https://img.shields.io/github/actions/workflow/status/VincentZyuApps/dart-flutter-demo/release-publish.yml?branch=main&logo=githubactions&label=build)](https://github.com/VincentZyuApps/dart-flutter-demo/actions) |


