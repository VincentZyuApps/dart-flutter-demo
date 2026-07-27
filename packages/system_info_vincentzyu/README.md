# system_info_vincentzyu

Typed system information for Flutter desktop and mobile applications.

```dart
final client = SystemInfoClient();
final snapshot = await client.collect(forceRefresh: true);

print(snapshot.operatingSystem);
print(snapshot.memoryTotalBytes);
print(snapshot.diagnostics.primarySource.name);
```

The package exposes raw values and leaves localized display formatting to the host app.
Windows uses native Win32 FFI first and only starts PowerShell when faster fallbacks leave required fields unavailable.

Each field includes its source, elapsed time, attempted fallbacks, and optional error.
`SystemInfoSessionLogSink` can mirror events to memory, a broadcast stream, the Flutter console, and rotating files. It defaults to 10 MiB per file and retains the newest five files.

Declared native baselines are Windows 10, Android API 21, iOS 13.0, and macOS 10.15. Linux collection uses Dart, `/proc`, and standard OS commands.
