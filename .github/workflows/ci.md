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

Every published application version, including versions with `alpha`, `beta`, or `rc` suffixes, is created as a regular non-draft Release and explicitly marked as the repository's Latest Release.

Only application Release Notes contain a commit log. The range starts after the nearest reachable application tag matching `v[0-9]*`; Performance, Profile, Debug, and Bootstrap outputs do not include commit history.

The pipeline first runs `flutter analyze`, root tests, local-plugin tests, and CI trigger tests. It then builds:

| 🎯 Target | 🖥️ Runner | 📦 Release output |
|---|---|---|
| Windows x64 | `windows-latest` | portable ZIP, Inno Setup EXE, and Store submission MSIX |
| Linux x64 | `ubuntu-22.04` | tar.gz, DEB, and AppImage |
| macOS x64 | `macos-15-intel` | DMG and ZIP |
| macOS ARM64 | `macos-latest` | DMG and ZIP |
| Android | `ubuntu-latest` | universal, ARM64, and x86_64 APKs |
| iOS ARM64 | `macos-latest` | unsigned IPA |

The same run builds permanent Profile assets for Windows x64, Linux x64, and Android Universal. Profile packages carry `-profile-` in their filenames.

### 🧪 Manual Dry-Run

Manual runs default to `publish=false`. They execute quality checks, all Release builds, all permanent Profile builds, packaging, MSIX validation, and release-note rendering, but upload a seven-day `release-dry-run-*` artifact instead of creating a tag or GitHub Release.

Set `publish=true` only after the dry-run passes. A push containing `build-release` publishes automatically after every required job succeeds.

## 📦 Flatpak Package Check

`flatpak-check.yml` is a manually triggered package-only workflow for an x86_64 `.flatpak`. It does not create a GitHub Release, update a Flatpak repository, use the production GPG key, or publish to Flathub.

The workflow builds the committed Linux application on `ubuntu-22.04`, preserves the complete Flutter bundle, and packages it inside the official Freedesktop `25.08` Flatpak container. The Flatpak branch is always `stable`; the application version and release date continue to come from `pubspec.yaml` independently.

The initial strict sandbox grants only network and IPC sharing, Wayland, fallback X11, and DRI rendering. It does not grant host or home filesystem access, unrestricted devices, or direct system/session bus access. System information that Flatpak does not safely expose may be unavailable or describe the sandbox until a narrower read-only integration is implemented and tested.

Run and download the seven-day package-only Artifact with:

```bash
gh workflow run flatpak-check.yml --ref main
RUN_ID="$(gh run list --workflow flatpak-check.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$RUN_ID" --exit-status
gh run download "$RUN_ID" --name "flatpak-package-only-$RUN_ID" --dir "tmp/downloads/ci/flatpak-package-only-$RUN_ID"
```

The workflow validates the desktop file and AppStream metadata, installs the generated bundle, checks the exact `app/io.github.vincentzyuapps.dartflutterdemo/x86_64/stable` ref and version, rejects broad sandbox permissions, and requires the application to remain running through a 20-second virtual-display smoke test.

The downloaded `.flatpak` is a versioned side-load bundle and does not configure automatic updates. After package-only testing succeeds, it will be added to `build-release.yml`; the separate `VincentZyuApps/flatpak-repo` GitHub Pages repository and its fixed `.flatpakref` will later provide signed automatic updates through `[build-publish]`.

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
| Windows | `dart-flutter-demo-windows-x64-v<version>.zip` / `-setup.exe` / `dart-flutter-demo-windows-x64-store-v<version>.msix` |
| Linux | `dart-flutter-demo-linux-x64-v<version>.tar.gz` / `.deb` / `.AppImage` |
| macOS | `dart-flutter-demo-macos-<arch>-v<version>.dmg` / `.zip` |
| Android | `dart-flutter-demo-android-<abi>-v<version>.apk` |
| iOS | `dart-flutter-demo-ios-arm64-v<version>.ipa` |
| Profile | `dart-flutter-demo-<platform>-profile-v<version>.<extension>` |
| Performance | `performance-summary-<UTC>-<sha>.md` / `.json`, per-platform `.md` / `.json`, and `performance-workflow-<UTC>-<sha>.log` |

The GitHub tag and filenames use the part of `pubspec.yaml` version before `+`. For example, `X.Y.Z-beta.W+YYYYMMDD` produces tag `vX.Y.Z-beta.W`.

## 🔐 Permissions And Signing

Only the app `publish` job and Performance `publish-report` job receive `contents: write`; all other jobs are read-only. Publishing uses the default `GITHUB_TOKEN`. No Team ID, certificate, provisioning profile, keystore, or signing secret is stored in the repository.

Android artifacts use ephemeral CI signing. The iOS IPA and macOS packages are unsigned. Self-sign the IPA for AltStore or configure signing in a separate private release process before TestFlight or App Store distribution.

## 🏪 External Publishing And Microsoft Store

> **🚧 Current status:** `flatpak-check.yml`, package-only Windows x64 MSIX builds, and the read-only Store authentication check are implemented. `build-publish` remains disabled until the signed `flatpak-repo` path has passed package, deployment, and public `stable` update tests. The Microsoft Store job remains separately disabled until the first Partner Center submission is Live.

The planned `build-publish` path extends `build-release`: it runs the same quality checks, Release builds, permanent Profile builds, GitHub Release publication, Flatpak packaging, and Windows x64 MSIX validation. It then publishes the signed Flatpak to the self-hosted repository after `flatpak-production` approval. Once the Store product is Live, a separate `microsoft-store-production` job will submit the same release's MSIX; Microsoft certification still runs afterward.

This project will remain free. Pre-release versions such as `vX.Y.Z-beta.W` will be submitted directly to the production Store listing, not to a Package Flight. Review the version and release notes carefully before approving the Environment deployment.

The existing Windows x64 portable ZIP and Inno Setup EXE remain GitHub Release assets. No MSI artifact is planned: MSI would duplicate the traditional installer role already covered by the EXE, require another packaging pipeline, and still require Authenticode signing. MSIX is the Store format; Microsoft re-signs it after certification, so a CA-issued signing certificate is not required for Store-only distribution.

### 🧾 First Manual Partner Center Submission

Microsoft currently supports GitHub Actions app updates only for free products that are already published and live. Complete these steps before enabling the Microsoft Store portion of `build-publish`:

1. Register a Windows developer account in [Partner Center](https://storedeveloper.microsoft.com/) and finish the requested identity verification.
2. From the Partner Center home page, open **Apps and games**, create a new product, select **MSIX or PWA app**, and reserve the app name.
3. Open the new product and select **Product identity** in the left navigation, then record the public Store and MSIX identity values described in the next section.
4. Associate an existing Microsoft Entra tenant with Partner Center, or create a tenant from Partner Center.
5. Register a Microsoft Entra application for CI, add it under Partner Center account user management, and assign it the **Manager** role.
6. Manually run `build-release.yml` with `publish=false`, download the seven-day `release-dry-run-*` artifact, and select the Windows x64 Store `.msix` inside it.
7. Follow the [Microsoft Store first-submission worksheet](../../doc/microsoft-store-submission.md), create the first Partner Center submission manually, upload that MSIX, complete listing, privacy, age-rating, availability, and policy information, and submit it for certification.
8. Wait until the product is published and shows as **Live** before configuring automatic updates.

The Store package version is separate from `pubspec.yaml` SemVer. It must contain four numeric fields, the first field cannot be zero, each field must be at most 65535, and the fourth field must be zero. The future workflow will generate and validate this value instead of passing `vX.Y.Z-beta.W` directly.

### 🪪 Product Identity Page

After creating the product, follow **Partner Center home -> Apps and games -> dart-flutter-demo -> Product identity**. The current product can also be opened directly on the [`9PP2SRN17C4F` product identity page](https://partner.microsoft.com/dashboard/products/9PP2SRN17C4F/identity). This page primarily contains public product identity values that may be used in the MSIX manifest, workflow configuration, or public documentation. Its MSA application ID is a product identity value, not a CI client credential.

The exact current values are:

| 🧩 Partner Center field | 📋 Current value | 🎯 Usage |
|---|---|---|
| Store ID | `9PP2SRN17C4F` | `MS_STORE_PRODUCT_ID`, public Store links, and the publishing target |
| Package/Identity/Name | `VincentZyu.dart-flutter-demo` | `MS_STORE_IDENTITY_NAME` and MSIX `Package/Identity/Name` |
| Package/Identity/Publisher | `CN=A12FF185-DB00-4CAC-ADE2-C501823ECC8F` | `MS_STORE_PUBLISHER` and MSIX `Package/Identity/Publisher` |
| Package/Properties/PublisherDisplayName | `VincentZyu` | `MS_STORE_PUBLISHER_DISPLAY_NAME` and MSIX PublisherDisplayName |
| Package Family Name (PFN) | `VincentZyu.dart-flutter-demo_j4jaay73mj39p` | Calculated by the Store from Package Identity; not declared separately in the manifest |
| Package SID | `S-1-15-2-4052166922-3111628424-3389906557-1246929253-1774262628-4171725999-764323245` | Calculated Store identity; unused by the current workflow |
| Store URL | `https://apps.microsoft.com/detail/9PP2SRN17C4F` | Public product link after the product is published |
| Store protocol link | `ms-windows-store://pdp/?productid=9PP2SRN17C4F` | Opens the Microsoft Store product page on Windows |
| MSA application ID | Not stored in the repository | The current `dart-flutter-demo.ae0811c38249` registration is Microsoft-account-only and must not be used as `PARTNER_CENTER_CLIENT_ID` |

`MS_STORE_DISPLAY_NAME` does not come from the Package Identity fields above. It is the repository's canonical application display name and is currently fixed to `DartFlutterDemo`. Do not substitute the product title `dart-flutter-demo` or the Dart package name for these fields. Use a separate single-tenant Entra application for CI and never commit its Client ID or credentials to the repository.

### 🔒 GitHub Environment And Repository Variables

In the GitHub repository, open **Settings -> Environments -> New environment**, create `microsoft-store-production`, and configure:

- required reviewers so a commit token alone cannot publish externally;
- deployment branches limited to `main` and `master`;
- prevent self-review when the repository plan supports it;
- the following four Environment secrets and five Repository variables.

The final configuration is **4 Environment secrets + 5 Repository variables**. Public Store/MSIX identities live in repository-level variables; only publishing credentials are protected by approval in the `microsoft-store-production` Environment.

Use Environment secrets rather than repository-wide secrets so they are released to the job only after approval:

| 🔐 Environment secret | 📍 Source | 🎯 Purpose |
|---|---|---|
| `PARTNER_CENTER_TENANT_ID` | Microsoft Entra tenant overview | Select the Partner Center-associated tenant |
| `PARTNER_CENTER_SELLER_ID` | Partner Center Legal info / Developer | Select the Store seller account |
| `PARTNER_CENTER_CLIENT_ID` | Microsoft Entra app registration | Identify the CI application |
| `PARTNER_CENTER_CLIENT_SECRET` | Microsoft Entra app registration secret value | Authenticate the CI application |

These credentials are not available on the product's **Product identity** page. Obtain them in this order:

1. In the [Microsoft Entra admin center](https://entra.microsoft.com/), open **Entra ID -> Overview** and copy **Tenant ID** as `PARTNER_CENTER_TENANT_ID`.
2. Open **Entra ID -> App registrations -> New registration**, create a dedicated application such as `dart-flutter-demo-store-ci`, select **Accounts in this organizational directory only (Single tenant)**, and leave Redirect URI empty. Copy its **Application (client) ID** as `PARTNER_CENTER_CLIENT_ID`. Do not reuse the MSA-only `dart-flutter-demo.ae0811c38249` registration.
3. In the new single-tenant application, open **Certificates & secrets -> Client secrets**, create a secret, and immediately copy its **Value** as `PARTNER_CENTER_CLIENT_SECRET`. Do not copy the Secret ID.
4. In Partner Center, open **Account settings -> Legal info -> Developer** and copy **Seller ID** as `PARTNER_CENTER_SELLER_ID`. Do not use Publisher, Store ID, Partner ID, or `CN=...`.
5. In Partner Center, open **Account settings -> User management -> Microsoft Entra applications**, add the new CI application, and assign it the **Manager (Windows)** role.

The current Entra portal entry points are listed below. The portal should populate the placeholder in the Credentials URL; do not put the real Client ID in documentation:

| 🌐 Entra page | 🔗 Entry URL or template | 📋 Field to copy |
|---|---|---|
| Tenant overview | `https://entra.microsoft.com/#view/Microsoft_AAD_IAM/EntraLanding.ReactView` | **Tenant ID** -> `PARTNER_CENTER_TENANT_ID` |
| App registrations list | `https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade/quickStartType~/null/sourceType/Microsoft_AAD_IAM` | Create or open the dedicated single-tenant `dart-flutter-demo-store-ci`, then copy **Application (client) ID** -> `PARTNER_CENTER_CLIENT_ID` |
| Certificates & secrets | `https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/__APPLICATION_CLIENT_ID__` | In that single-tenant app, create a client secret and copy its one-time **Value** -> `PARTNER_CENTER_CLIENT_SECRET` |

`AADSTS9002331` means the selected registration accepts Microsoft Account users only and cannot use the tenant client-credential flow. Create a single-tenant Entra app as described above instead of changing the token endpoint to `/consumers`.

The confirmed Seller ID entry is the [Developer page under Partner Center Legal info](https://partner.microsoft.com/dashboard/account/v3/organization/legalinfo#developer). Copy **Seller ID** from that page as `PARTNER_CENTER_SELLER_ID`.

`https://partner.microsoft.com/dashboard/account/v3/overview` is the new **Account settings | Overview** page, not the product identity page. A search that returns no result for “tenant” does not prove that no tenant exists. Expand the upper-left navigation menu and look for **Tenants** or **User management**. If those entries are unavailable, verify that the signed-in account belongs to the associated Entra tenant, the correct tenant is selected, and the account has the Partner Center **Manager** role.

Add these non-secret Repository variables using the exact values from the product identity page:

| 🔧 Repository variable | 📍 Source | 🎯 Purpose |
|---|---|---|
| `MS_STORE_PRODUCT_ID` | Store ID on the Product identity page | Select the app submission target |
| `MS_STORE_IDENTITY_NAME` | Package/Identity/Name on the Product identity page | Populate `Package/Identity/Name` |
| `MS_STORE_PUBLISHER` | Package/Identity/Publisher on the Product identity page | Populate the manifest Publisher |
| `MS_STORE_PUBLISHER_DISPLAY_NAME` | Package/Properties/PublisherDisplayName on the Product identity page | Populate the visible publisher name |
| `MS_STORE_DISPLAY_NAME` | Repository application branding | Populate the visible application name, currently `DartFlutterDemo` |

Run these commands from the repository root to create or replace the five non-secret Repository variables:

```bash
gh variable set MS_STORE_PRODUCT_ID --body "9PP2SRN17C4F"
gh variable set MS_STORE_IDENTITY_NAME --body "VincentZyu.dart-flutter-demo"
gh variable set MS_STORE_PUBLISHER --body "CN=A12FF185-DB00-4CAC-ADE2-C501823ECC8F"
gh variable set MS_STORE_PUBLISHER_DISPLAY_NAME --body "VincentZyu"
gh variable set MS_STORE_DISPLAY_NAME --body "DartFlutterDemo"
```

Write the four publishing credentials interactively as Environment secrets. Run each command and paste its corresponding value at the prompt. Do not put real values in command arguments, shell history, documentation, or chat messages:

```bash
gh secret set PARTNER_CENTER_TENANT_ID --env microsoft-store-production
gh secret set PARTNER_CENTER_SELLER_ID --env microsoft-store-production
gh secret set PARTNER_CENTER_CLIENT_ID --env microsoft-store-production
gh secret set PARTNER_CENTER_CLIENT_SECRET --env microsoft-store-production
```

GitHub does not allow secret values to be read back, but their names can be verified:

```bash
gh variable list
gh secret list --env microsoft-store-production
```

### 🔎 Read-Only Authentication Check

After granting the selected Entra application the Partner Center **Manager** role, manually run the dedicated authentication check from `main`:

```bash
gh workflow run microsoft-store-auth-check.yml --ref main
RUN_ID="$(gh run list --workflow microsoft-store-auth-check.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$RUN_ID" --exit-status
gh run view "$RUN_ID" --log-failed
```

The second command captures the newest run ID, the third follows it to completion and returns a nonzero exit code on failure, and the fourth prints failed-step logs when troubleshooting. The workflow enters `microsoft-store-production`, installs the official Microsoft Store App Publisher action pinned to `v1.4` and Microsoft Store Developer CLI `v0.3.9`, authenticates with the four Environment secrets, and runs only `msstore apps list`. It never creates a submission, uploads a package, edits metadata, or publishes an app. A successful run confirms that Microsoft accepts the credentials and permits read access; inspect its app list for Store ID `9PP2SRN17C4F` before the first manual submission.

`GITHUB_TOKEN` is supplied automatically and does not need to be created. A Store-only MSIX does not require a PFX secret because Microsoft signs the package after certification. Never put the client secret, tenant credentials, certificates, or their encoded forms in source files, logs, artifacts, or Release notes.

### 🚀 Automatic Publication

After the signed Flatpak repository is initialized and the workflow is enabled, use:

```text
release: publish DartFlutterDemo

[build-publish]
```

The workflow will build all normal Release/Profile artifacts, create the GitHub Release, attach the versioned `.flatpak`, pause for `flatpak-production` approval, and update the signed `stable` repository. After the Store product is Live and its job is enabled, it will also pause independently for `microsoft-store-production` approval and submit the MSIX. Reject either deployment when its version, changelog, identity, or generated package is unexpected.

Rotate `PARTNER_CENTER_CLIENT_SECRET` before it expires and update only the Environment secret value. If certification later fails, inspect Partner Center; do not treat the earlier GitHub job success as proof that the update is live.

### 📚 Official References

- [Publish app updates with GitHub Actions](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/github-actions)
- [Associate an existing Microsoft Entra ID tenant with Partner Center](https://learn.microsoft.com/windows/apps/publish/partner-center/associate-existing-azure-ad-tenant-with-partner-center-account)
- [Register an application in Microsoft Entra ID](https://learn.microsoft.com/entra/identity-platform/quickstart-register-app)
- [Microsoft Store Developer CLI for MSIX](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/overview)
- [Microsoft Store Developer CLI commands](https://learn.microsoft.com/windows/apps/publish/msstore-dev-cli/commands)
- [Microsoft Store MSIX package requirements](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/app-package-requirements)
- [Official Microsoft Store App Publisher Action](https://github.com/microsoft/microsoft-store-apppublisher)
