> **[📖 English](ci.md)** | **[📖 Simplified Chinese](ci.zh-cn.md)**

# ⚙️ GitHub Actions Workflows

This repository uses Flutter 3.41.5 in GitHub Actions. Normal CI consumes the committed `android/`, `ios/`, `windows/`, `linux/`, and `macos/` projects. It never runs `flutter create` and never patches generated runners.

## 📝 Commit Convention

Use a Conventional Commit summary on the first line. Put CI tokens at the end of the message:

```text
feat(system-info): migrate collection into a reusable plugin

[build-profile]
[run-performance]
```

Tokens are exact, case-sensitive, and hyphenated. Brackets are style punctuation and are not part of matching.

| 🔑 Token | ⚙️ Workflow | 📦 Output | ⏳ Retention | 🚀 Creates Release |
|---|---|---|---|:---:|
| `build-release` | `build-release.yml` | Six Release targets plus three Profile targets | Permanent after publishing | Yes |
| `build-profile` | `profile-debug.yml` | Windows x64, Linux x64, Android Universal Profile | 7 days | No |
| `build-debug` | `profile-debug.yml` | Windows x64, Linux x64, Android Universal Debug | 7 days | No |
| `run-performance` | `performance.yml` | Windows, Linux, and macOS JSON/Markdown/log bundle | 7 days | No |
| `release-performance` | `performance.yml` | The same complete performance bundle | Permanent Performance Pre-release | Yes |

Legacy forms such as `build release`, `build action`, or `BUILD-RELEASE` do not match. Multiple valid tokens in one commit may start multiple workflows.

## 🚀 Build Release

`build-release.yml` runs on a push containing `build-release`, or through `workflow_dispatch`.

The pipeline first runs `flutter analyze`, root tests, local-plugin tests, and CI trigger tests. It then builds:

| 🎯 Target | 🖥️ Runner | 📦 Release output |
|---|---|---|
| Windows x64 | `windows-latest` | portable ZIP and Inno Setup EXE |
| Linux x64 | `ubuntu-22.04` | tar.gz, DEB, and AppImage |
| macOS x64 | `macos-15-intel` | DMG and ZIP |
| macOS ARM64 | `macos-latest` | DMG and ZIP |
| Android | `ubuntu-latest` | universal, ARM64, and x86_64 APKs |
| iOS ARM64 | `macos-latest` | unsigned IPA |

The same run builds permanent Profile assets for Windows x64, Linux x64, and Android Universal. Profile packages carry `-profile-` in their filenames.

### 🧪 Manual Dry-Run

Manual runs default to `publish=false`. They execute quality checks, all Release builds, all permanent Profile builds, packaging, and release-note rendering, but upload a seven-day `release-dry-run-*` artifact instead of creating a tag or GitHub Release.

Set `publish=true` only after the dry-run passes. A push containing `build-release` publishes automatically after every required job succeeds.

## 🧰 Profile And Debug Builds

`profile-debug.yml` accepts `build-profile` and `build-debug`. A message containing both tokens creates both sets. A manual run offers `profile`, `debug`, and `both` choices.

Artifact examples:

```text
dart-flutter-demo-windows-x64-profile-93ac817
dart-flutter-demo-linux-x64-debug-93ac817
dart-flutter-demo-android-universal-profile-93ac817
```

These are temporary Actions artifacts, not GitHub Release assets.

## 📊 Performance Reports

`performance.yml` supports `run-performance` for a seven-day Artifact and `release-performance` for a permanent Performance Pre-release. Manual runs offer `artifact-7-days` and `github-release`, defaulting to the temporary option.

Its Monday 03:00 UTC schedule is declared but initially disabled by `ENABLE_SCHEDULED_PERFORMANCE: 'false'`. Set it to `'true'` to enable the schedule; `SCHEDULED_PERFORMANCE_DESTINATION` independently selects `artifact` or `release` and defaults to `artifact`.

When started, it builds Profile bundles on Windows x64, Linux x64, and macOS ARM64, then records build time, artifact size, file count, largest files, and changes from the previous successful report. Three one-day staging artifacts are consolidated into one final seven-day bundle.

Each final bundle contains:

- 📝 a bilingual summary in Markdown and JSON;
- 🖥️ per-platform Markdown and JSON reports, for six files total;
- 🧾 one combined log covering the completed preparation job and all three platform jobs.

The baseline first uses the latest unexpired seven-day performance Artifact and falls back to the newest permanent Performance Pre-release. Expired temporary runs therefore do not break long-term comparisons when a permanent report exists.

Permanent reports use unique `performance-<UTC>-<sha>-run<id>-attempt<n>` tags and are explicitly marked as Pre-releases, so they do not replace the app's Latest Release. The same nine files are attached, and the bilingual summary is rendered as the Release body.

Performance changes are informational; only structural errors such as a failed build, an incomplete three-platform set, missing logs, or invalid JSON fail the workflow. Hosted-runner data is useful for trends, not precise device FPS, memory, or startup benchmarks.

## 🏗️ Platform Bootstrap

`platform-bootstrap.yml` has no commit token and is manual-only. It creates all five platform projects in a GitHub-hosted temporary directory, applies:

- application ID `io.github.vincentzyuapps.dartflutterdemo`;
- display name `DartFlutterDemo`;
- committed app icons;
- the App-specific Android home widget.

It uploads `dart-flutter-demo-platform-roots-flutter-3.41.5` for seven days, including the five roots, Flutter `.metadata`, and the root dependency `pubspec.lock`, and never commits it. Download and review the artifact before replacing the repository platform roots. This workflow is intended for the initial migration and deliberate future Flutter template upgrades.

## 📦 Final Release Filenames

| 🧩 Type | 📝 Pattern |
|---|---|
| Windows | `dart-flutter-demo-windows-x64-v<version>.zip` / `-setup.exe` |
| Linux | `dart-flutter-demo-linux-x64-v<version>.tar.gz` / `.deb` / `.AppImage` |
| macOS | `dart-flutter-demo-macos-<arch>-v<version>.dmg` / `.zip` |
| Android | `dart-flutter-demo-android-<abi>-v<version>.apk` |
| iOS | `dart-flutter-demo-ios-arm64-v<version>.ipa` |
| Profile | `dart-flutter-demo-<platform>-profile-v<version>.<extension>` |
| Performance | `performance-summary-<UTC>-<sha>.md` / `.json`, per-platform `.md` / `.json`, and `performance-workflow-<UTC>-<sha>.log` |

The GitHub tag and filenames use the part of `pubspec.yaml` version before `+`. For example, `0.4.2-beta.8+20260727` produces tag `v0.4.2-beta.8`.

## 🔐 Permissions And Signing

Only the app `publish` job and Performance `publish-report` job receive `contents: write`; all other jobs are read-only. Publishing uses the default `GITHUB_TOKEN`. No Team ID, certificate, provisioning profile, keystore, or signing secret is stored in the repository.

Android artifacts use ephemeral CI signing. The iOS IPA and macOS packages are unsigned. Self-sign the IPA for AltStore or configure signing in a separate private release process before TestFlight or App Store distribution.

## 🏪 Microsoft Store Onboarding And `build-publish`

> **🚧 Current status:** `build-publish` is reserved but not enabled yet. Do not use it until the first Partner Center submission is live, the MSIX identity values have been reviewed, and the Store publishing job has been implemented and tested.

The planned `build-publish` path extends `build-release`: it runs the same quality checks, Release builds, permanent Profile builds, and GitHub Release publication, then creates a Windows x64 MSIX and waits for approval in the `microsoft-store-production` GitHub Environment before submitting it to Microsoft Store. A successful workflow means that the submission reached Partner Center; Microsoft certification still runs afterward.

This project will remain free. Pre-release versions such as `0.5.0-beta.9` will be submitted directly to the production Store listing, not to a Package Flight. Review the version and release notes carefully before approving the Environment deployment.

The existing Windows x64 portable ZIP and Inno Setup EXE remain GitHub Release assets. No MSI artifact is planned: MSI would duplicate the traditional installer role already covered by the EXE, require another packaging pipeline, and still require Authenticode signing. MSIX is the Store format; Microsoft re-signs it after certification, so a CA-issued signing certificate is not required for Store-only distribution.

### 🧾 First Manual Partner Center Submission

Microsoft currently supports GitHub Actions app updates only for free products that are already published and live. Complete these steps before enabling `build-publish`:

1. Register a Windows developer account in [Partner Center](https://storedeveloper.microsoft.com/) and finish the requested identity verification.
2. Reserve the app name and create the product in Partner Center.
3. Associate an existing Microsoft Entra tenant with Partner Center, or create a tenant from Partner Center.
4. Register a Microsoft Entra application for CI, add it under Partner Center account user management, and assign it the **Manager** role.
5. Open the product identity page and record the Product ID, Package/Identity/Name, Publisher, Publisher display name, and app display name exactly as shown. These values must not be guessed from the Dart package name.
6. After the repository's MSIX packaging job is implemented, run its manual package-only dry-run and download the Windows x64 `.msix` artifact.
7. Create the first Partner Center submission manually, upload that MSIX, complete listing, privacy, age-rating, availability, and policy information, and submit it for certification.
8. Wait until the product is published and shows as **Live** before configuring automatic updates.

The Store package version is separate from `pubspec.yaml` SemVer. It must contain four numeric fields, the first field cannot be zero, each field must be at most 65535, and the fourth field must be zero. The future workflow will generate and validate this value instead of passing `0.5.0-beta.9` directly.

### 🔒 GitHub Environment

In the GitHub repository, open **Settings -> Environments -> New environment**, create `microsoft-store-production`, and configure:

- required reviewers so a commit token alone cannot publish externally;
- deployment branches limited to `main` and `master`;
- prevent self-review when the repository plan supports it;
- the following Environment secrets and variables.

Use Environment secrets rather than repository-wide secrets so they are released to the job only after approval:

| 🔐 Environment secret | 📍 Source | 🎯 Purpose |
|---|---|---|
| `PARTNER_CENTER_TENANT_ID` | Microsoft Entra tenant overview | Select the Partner Center-associated tenant |
| `PARTNER_CENTER_SELLER_ID` | Partner Center account settings / identifiers | Select the Store seller account |
| `PARTNER_CENTER_CLIENT_ID` | Microsoft Entra app registration | Identify the CI application |
| `PARTNER_CENTER_CLIENT_SECRET` | Microsoft Entra app registration secret value | Authenticate the CI application |

Add these non-secret Environment variables using the exact values from the product identity page:

| 🔧 Environment variable | 📍 Source | 🎯 Purpose |
|---|---|---|
| `MS_STORE_PRODUCT_ID` | Partner Center product overview | Select the app submission target |
| `MS_STORE_IDENTITY_NAME` | Package identity details | Populate `Package/Identity/Name` |
| `MS_STORE_PUBLISHER` | Package identity details | Populate the manifest Publisher, usually a `CN=...` value |
| `MS_STORE_PUBLISHER_DISPLAY_NAME` | Partner Center identity details | Populate the visible publisher name |
| `MS_STORE_DISPLAY_NAME` | Partner Center product identity | Populate the visible app name, expected to be `DartFlutterDemo` |

`GITHUB_TOKEN` is supplied automatically and does not need to be created. A Store-only MSIX does not require a PFX secret because Microsoft signs the package after certification. Never put the client secret, tenant credentials, certificates, or their encoded forms in source files, logs, artifacts, or Release notes.

### 🚀 Automatic Publication

After onboarding is complete and the workflow is enabled, use:

```text
release: publish DartFlutterDemo

[build-publish]
```

The workflow will build all normal Release/Profile artifacts, create the GitHub Release, build the Windows x64 Store MSIX, pause for `microsoft-store-production` approval, configure the official Microsoft Store Developer CLI, and submit the MSIX to the production listing. Reject the deployment when the version, changelog, Store identity, or generated package is unexpected.

Rotate `PARTNER_CENTER_CLIENT_SECRET` before it expires and update only the Environment secret value. If certification later fails, inspect Partner Center; do not treat the earlier GitHub job success as proof that the update is live.

### 📚 Official References

- [Publish app updates with GitHub Actions](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/github-actions)
- [Microsoft Store Developer CLI for MSIX](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/overview)
- [Microsoft Store Developer CLI commands](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/commands)
- [Microsoft Store MSIX package requirements](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/app-package-requirements)
- [Official Microsoft Store App Publisher Action](https://github.com/microsoft/microsoft-store-apppublisher)
