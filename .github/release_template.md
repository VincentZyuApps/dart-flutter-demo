<div align=center>

[![Downloads](https://img.shields.io/github/downloads/__REPO__/v__VERSION__/total?style=flat-square&logo=github)](https://github.com/__REPO__/releases/tag/v__VERSION__)

</div>


### ⬇️ Downloads

| OS / Arch | x86_64 | ARM64 | Universal |
|-----------|--------|-------|-----------|
| **Windows** | [![windows-x64-setup-exe](https://img.shields.io/badge/windows-x64.setup.exe-0078D4.svg?logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](__BASE_URL__/dart-flutter-demo-windows-x64-v__VERSION__-setup.exe) · [![windows-x64-portable-zip](https://img.shields.io/badge/windows-x64.portable.zip-67b7d1.svg?logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTAgMGgxMS4zNzd2MTEuMzcySDB6TTEyLjYyMyAwSDI0djExLjM3MkgxMi42MjN6TTAgMTIuNjIzaDExLjM3N1YyNEgweiBNMTIuNjIzIDEyLjYyM0gyNFYyNEgxMi42MjN6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](__BASE_URL__/dart-flutter-demo-windows-x64-v__VERSION__.zip) | — | — |
| **Linux** | [![linux-x64-appimage](https://img.shields.io/badge/linux-x64.AppImage-FCC624.svg?logo=linux)](__BASE_URL__/dart-flutter-demo-linux-x64-v__VERSION__.AppImage) · [![linux-x64-deb](https://img.shields.io/badge/linux-x64.deb-CE0056.svg?logo=debian)](__BASE_URL__/dart-flutter-demo-linux-x64-v__VERSION__.deb) · [![linux-x64-tar-gz](https://img.shields.io/badge/linux-x64.tar.gz-2E3440.svg?logo=linux)](__BASE_URL__/dart-flutter-demo-linux-x64-v__VERSION__.tar.gz) | — | — |
| **macOS** | [![macos-x64-dmg](https://img.shields.io/badge/macOS-x64.dmg-8E8E93.svg?logo=apple)](__BASE_URL__/dart-flutter-demo-macos-x64-v__VERSION__.dmg) · [![macos-x64-zip](https://img.shields.io/badge/macOS-x64.zip-4A4A4F.svg?logo=apple)](__BASE_URL__/dart-flutter-demo-macos-x64-v__VERSION__.zip) | [![macos-arm64-dmg](https://img.shields.io/badge/macOS-ARM64.dmg-8E8E93.svg?logo=apple)](__BASE_URL__/dart-flutter-demo-macos-arm64-v__VERSION__.dmg) · [![macos-arm64-zip](https://img.shields.io/badge/macOS-ARM64.zip-4A4A4F.svg?logo=apple)](__BASE_URL__/dart-flutter-demo-macos-arm64-v__VERSION__.zip) | — |
| **Android** | [![android-x64](https://img.shields.io/badge/android-x64.apk-8FE388.svg?logo=android)](__BASE_URL__/dart-flutter-demo-android-x86_64-v__VERSION__.apk) | [![android-arm64](https://img.shields.io/badge/android-ARM64.apk-168039.svg?logo=android)](__BASE_URL__/dart-flutter-demo-android-arm64-v__VERSION__.apk) | [![android-universal](https://img.shields.io/badge/android-universal.apk-3DDC84.svg?logo=android)](__BASE_URL__/dart-flutter-demo-android-universal-v__VERSION__.apk) |
| **iOS** | — | [![ios-arm64](https://img.shields.io/badge/iOS-ARM64.ipa-000000.svg?logo=apple)](__BASE_URL__/dart-flutter-demo-ios-arm64-v__VERSION__.ipa) | — |

> #### Profile Builds
>
> These AOT-compiled Profile packages keep profiling support and are intended for measurements on your own hardware. They are not production Release builds.
>
> - [Windows x64 Profile ZIP](__BASE_URL__/dart-flutter-demo-windows-x64-profile-v__VERSION__.zip)
> - [Linux x64 Profile tar.gz](__BASE_URL__/dart-flutter-demo-linux-x64-profile-v__VERSION__.tar.gz)
> - [Android Universal Profile APK](__BASE_URL__/dart-flutter-demo-android-universal-profile-v__VERSION__.apk)
>
> #### Installation & Compatibility Notes
>
> `—` means this OS/architecture combination does not have a published artifact in the current build matrix.
>
> ⚠️ **Linux / Windows GPU issues**: If the app fails to render correctly, launch it with software rendering: `./dart_flutter_demo --disable-gpu`
>
> ⚠️ **macOS security prompt**: If macOS blocks the app because Apple cannot verify it, open **System Settings → Privacy & Security**, scroll down to **Security**, then click **Open Anyway** for `dart_flutter_demo`.
>
> ⚠️ **macOS virtual machines**: Flutter desktop apps require Apple Metal, which is unavailable in VMware, VirtualBox, and similar VMs. Use a physical Mac or [GitHub Actions macOS runners](https://github.com/VincentZyuApps/mac-test-action-runner) instead.
>
> ⚠️ **Android**: APKs are not signed with a persistent keystore, so you must uninstall the previous version before installing a new one to avoid signature conflicts.
>
> ⚠️ **iOS**: The IPA is not code-signed for personal devices. To install it on your own iPhone or iPad, self-sign it first. You can use self-signing tools such as AltStore/AltServer or other solutions. For example, see the self-signing guide in the [Troubleshooting section](https://github.com/VincentZyuApps/dart-flutter-demo#%EF%B8%8F-troubleshooting) of the README.

### 📄 Git Information

__BUILD_INFO__

### Commit Log

__COMMIT_LOG__
