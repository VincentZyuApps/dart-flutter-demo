# Windows System Information Migration Record

## Previous State

The Windows runner was generated during every CI run. Native C++ files were copied from `plugins/windows/`, and a Python script patched the generated CMake project so Dart FFI could find functions compiled into the runner executable. This coupled the build to exact Flutter template text and required a separate PowerShell file in the packaged app.

## Implemented Architecture

System information now lives in the reusable local Flutter plugin at `packages/system_info_vincentzyu/`.

- The standard Windows plugin target builds `system_info_vincentzyu_plugin.dll`.
- Flutter plugin registration ensures the DLL is bundled and loaded normally.
- `SystemInfoVincentzyuGetJson` and `SystemInfoVincentzyuFreeJson` are exported for Dart FFI.
- The native payload returns typed raw values such as seconds and byte counts.
- Dart formats values only in the host App layer.
- Field diagnostics record source, elapsed time, attempts, and errors.
- Windows FFI is first, native commands and `dart:io` are intermediate fallbacks, and the packaged PowerShell asset is last.

## Platform Project Ownership

The committed `windows/` project is generated once by `.github/workflows/platform-bootstrap.yml` with Flutter 3.41.5 and then reviewed as source. Build Release, Profile & Debug Builds, and Performance workflows must not call `flutter create`, copy native plugin files, or patch the runner.

## Validation Gates

The migration is complete after the bootstrap artifact is committed and GitHub Actions passes:

1. Windows x64 Debug and Profile developer builds.
2. Windows x64 Profile performance report.
3. Release dry-run with the portable ZIP and Inno Setup installer.
4. A system-info page check confirming `windowsFfi` is the normal source and PowerShell was not attempted.
