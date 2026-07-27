import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'model/system_info_diagnostics.dart';
import 'model/system_info_event.dart';
import 'model/system_info_field.dart';
import 'model/system_info_snapshot.dart';
import 'model/system_info_source.dart';

typedef SystemInfoEventListener = void Function(SystemInfoEvent event);
typedef SystemInfoFieldListener = void Function(
  SystemInfoField field,
  Object value,
  SystemInfoFieldDiagnostic diagnostic,
);

typedef _GetSystemInfoJsonNative = Pointer<Utf8> Function();
typedef _GetSystemInfoJsonDart = Pointer<Utf8> Function();
typedef _FreeSystemInfoJsonNative = Void Function(Pointer<Utf8>);
typedef _FreeSystemInfoJsonDart = void Function(Pointer<Utf8>);

class SystemInfoClient {
  SystemInfoClient({this.onEvent});

  static const MethodChannel _channel = MethodChannel(
    'system_info_vincentzyu/methods',
  );

  final SystemInfoEventListener? onEvent;
  SystemInfoSnapshot? _cache;

  Future<SystemInfoSnapshot> collect({
    bool forceRefresh = false,
    SystemInfoFieldListener? onField,
  }) async {
    if (!forceRefresh && _cache != null) {
      final cached = _withCacheDiagnostics(_cache!);
      _emit(
        SystemInfoLogLevel.debug,
        'Returned cached system information.',
        SystemInfoSource.cache,
      );
      _notifyFields(cached, onField);
      return cached;
    }

    final snapshot = switch (Platform.operatingSystem) {
      'windows' => await _collectWindows(),
      'linux' => await _collectLinux(),
      'android' => await _collectMethodChannel(
          SystemInfoSource.androidMethodChannel,
        ),
      'ios' => await _collectMethodChannel(SystemInfoSource.iosMethodChannel),
      'macos' =>
        await _collectMethodChannel(SystemInfoSource.macosMethodChannel),
      _ => await _collectDartFallback(),
    };
    _cache = snapshot;
    _notifyFields(snapshot, onField);
    return snapshot;
  }

  void clearCache() => _cache = null;

  Future<SystemInfoSnapshot> _collectMethodChannel(
    SystemInfoSource source,
  ) async {
    final stopwatch = Stopwatch()..start();
    final attempts = <SystemInfoSource>[source];
    final errors = <String>[];
    final sources = <SystemInfoField, SystemInfoSource>{};
    final fieldAttempts = <SystemInfoField, List<SystemInfoSource>>{
      for (final field in SystemInfoField.values) field: <SystemInfoSource>[source],
    };
    Map<String, Object?> values = <String, Object?>{};
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('getInfo');
      values = Map<String, Object?>.from(result ?? const <String, Object?>{});
      for (final field in SystemInfoField.values) {
        if (_isUsable(values[field.wireName])) sources[field] = source;
      }
      _emit(SystemInfoLogLevel.info, 'Native MethodChannel completed.', source,
          elapsed: stopwatch.elapsed);
    } catch (error) {
      errors.add('$source: $error');
      _emit(SystemInfoLogLevel.warning, 'MethodChannel failed: $error', source,
          elapsed: stopwatch.elapsed);
    }

    final missing = _missingFields(values);
    if (missing.isNotEmpty) {
      attempts.add(SystemInfoSource.dartIoFallback);
      _recordAttempts(
        fieldAttempts,
        missing,
        SystemInfoSource.dartIoFallback,
      );
      final fallback = await _dartIoValues();
      _merge(values, sources, fallback, SystemInfoSource.dartIoFallback);
    }
    stopwatch.stop();
    return _snapshotFromValues(
      values,
      platform: Platform.operatingSystem,
      primarySource: source,
      elapsed: stopwatch.elapsed,
      attempts: attempts,
      errors: errors,
      fieldSources: sources,
      fieldAttempts: fieldAttempts,
    );
  }

  Future<SystemInfoSnapshot> _collectWindows() async {
    final stopwatch = Stopwatch()..start();
    final attempts = <SystemInfoSource>[];
    final errors = <String>[];
    final sources = <SystemInfoField, SystemInfoSource>{};
    final fieldAttempts = <SystemInfoField, List<SystemInfoSource>>{
      for (final field in SystemInfoField.values)
        field: <SystemInfoSource>[SystemInfoSource.windowsFfi],
    };
    final values = <String, Object?>{};

    attempts.add(SystemInfoSource.windowsFfi);
    try {
      final ffiValues = _windowsFfiValues();
      _merge(values, sources, ffiValues, SystemInfoSource.windowsFfi);
      _emit(SystemInfoLogLevel.info, 'Windows Win32 FFI completed.',
          SystemInfoSource.windowsFfi,
          elapsed: stopwatch.elapsed);
    } catch (error) {
      errors.add('windowsFfi: $error');
      _emit(SystemInfoLogLevel.warning, 'Windows FFI failed: $error',
          SystemInfoSource.windowsFfi,
          elapsed: stopwatch.elapsed);
    }

    if (_missingFields(values).isNotEmpty) {
      attempts.add(SystemInfoSource.windowsNativeCommand);
      _recordAttempts(
        fieldAttempts,
        _missingFields(values),
        SystemInfoSource.windowsNativeCommand,
      );
      try {
        final nativeValues = await _windowsNativeCommandValues();
        _merge(values, sources, nativeValues,
            SystemInfoSource.windowsNativeCommand);
      } catch (error) {
        errors.add('windowsNativeCommand: $error');
      }
    }

    if (_missingFields(values).isNotEmpty) {
      attempts.add(SystemInfoSource.dartIoFallback);
      _recordAttempts(
        fieldAttempts,
        _missingFields(values),
        SystemInfoSource.dartIoFallback,
      );
      final fallback = await _dartIoValues();
      _merge(values, sources, fallback, SystemInfoSource.dartIoFallback);
    }

    if (_missingFields(values).isNotEmpty) {
      attempts.add(SystemInfoSource.powershellScript);
      _recordAttempts(
        fieldAttempts,
        _missingFields(values),
        SystemInfoSource.powershellScript,
      );
      try {
        final powershellValues = await _windowsPowerShellValues();
        _merge(values, sources, powershellValues,
            SystemInfoSource.powershellScript);
        _emit(SystemInfoLogLevel.warning,
            'PowerShell fallback was required for missing fields.',
            SystemInfoSource.powershellScript,
            elapsed: stopwatch.elapsed);
      } catch (error) {
        errors.add('powershellScript: $error');
        _emit(SystemInfoLogLevel.error, 'PowerShell fallback failed: $error',
            SystemInfoSource.powershellScript,
            elapsed: stopwatch.elapsed);
      }
    }

    stopwatch.stop();
    return _snapshotFromValues(
      values,
      platform: 'windows',
      primarySource: sources.values.contains(SystemInfoSource.windowsFfi)
          ? SystemInfoSource.windowsFfi
          : (sources.isEmpty
              ? SystemInfoSource.unavailable
              : sources.values.first),
      elapsed: stopwatch.elapsed,
      attempts: attempts,
      errors: errors,
      fieldSources: sources,
      fieldAttempts: fieldAttempts,
    );
  }

  Map<String, Object?> _windowsFfiValues() {
    Object? lastError;
    for (final name in <String>[
      'system_info_vincentzyu_plugin.dll',
      'system_info_vincentzyu.dll',
    ]) {
      try {
        final library = DynamicLibrary.open(name);
        final getJson = library.lookupFunction<_GetSystemInfoJsonNative,
            _GetSystemInfoJsonDart>('SystemInfoVincentzyuGetJson');
        final freeJson = library.lookupFunction<_FreeSystemInfoJsonNative,
            _FreeSystemInfoJsonDart>('SystemInfoVincentzyuFreeJson');
        final pointer = getJson();
        if (pointer == nullptr) throw StateError('FFI returned a null pointer.');
        try {
          return Map<String, Object?>.from(
            jsonDecode(pointer.toDartString()) as Map,
          );
        } finally {
          freeJson(pointer);
        }
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Unable to load Windows plugin DLL: $lastError');
  }

  Future<Map<String, Object?>> _windowsNativeCommandValues() async {
    final values = <String, Object?>{};
    final version = await Process.run(
      'cmd.exe',
      const <String>['/c', 'ver'],
      runInShell: false,
    );
    if (version.exitCode == 0) {
      values['operatingSystem'] = version.stdout.toString().trim();
    }
    final registry = await Process.run(
      'reg.exe',
      <String>[
        'query',
        r'HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0',
        '/v',
        'ProcessorNameString',
      ],
      runInShell: false,
    );
    if (registry.exitCode == 0) {
      final match = RegExp(r'ProcessorNameString\s+REG_SZ\s+(.+)',
              caseSensitive: false)
          .firstMatch(registry.stdout.toString());
      if (match != null) values['cpuModel'] = match.group(1)?.trim();
    }
    return values;
  }

  Future<Map<String, Object?>> _windowsPowerShellValues() async {
    final script = await rootBundle.loadString(
      'packages/system_info_vincentzyu/assets/windows/SystemInfo.ps1',
    );
    final temp = await Directory.systemTemp.createTemp('system_info_vincentzyu_');
    final scriptFile = File('${temp.path}${Platform.pathSeparator}SystemInfo.ps1');
    try {
      await scriptFile.writeAsString(script, flush: true);
      final result = await Process.run(
        'powershell.exe',
        <String>[
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          scriptFile.path,
        ],
        runInShell: false,
      );
      if (result.exitCode != 0) {
        throw ProcessException(
          'powershell.exe',
          const <String>[],
          result.stderr.toString().trim(),
          result.exitCode,
        );
      }
      return Map<String, Object?>.from(
        jsonDecode(result.stdout.toString()) as Map,
      );
    } finally {
      try {
        await temp.delete(recursive: true);
      } on FileSystemException {
        // Temporary fallback files are best-effort cleanup only.
      }
    }
  }

  Future<SystemInfoSnapshot> _collectLinux() async {
    final total = Stopwatch()..start();
    final values = <String, Object?>{};
    final sources = <SystemInfoField, SystemInfoSource>{};
    final fieldAttempts = <SystemInfoField, List<SystemInfoSource>>{};
    final errors = <String>[];

    Future<void> read(
      SystemInfoSource source,
      Future<Map<String, Object?>> Function() loader,
    ) async {
      final missing = _missingFields(values);
      if (missing.isEmpty) return;
      _recordAttempts(fieldAttempts, missing, source);
      try {
        _merge(values, sources, await loader(), source);
      } catch (error) {
        errors.add('$source: $error');
      }
    }

    await read(SystemInfoSource.linuxDartIo, _linuxDartValues);
    if (_missingFields(values).isNotEmpty) {
      await read(SystemInfoSource.linuxNativeCommand, _linuxCommandValues);
    }
    if (_missingFields(values).isNotEmpty) {
      await read(SystemInfoSource.dartIoFallback, _dartIoValues);
    }
    total.stop();
    _emit(SystemInfoLogLevel.info, 'Linux collection completed.',
        SystemInfoSource.linuxDartIo,
        elapsed: total.elapsed);
    return _snapshotFromValues(
      values,
      platform: 'linux',
      primarySource: SystemInfoSource.linuxDartIo,
      elapsed: total.elapsed,
      attempts: const <SystemInfoSource>[
        SystemInfoSource.linuxDartIo,
        SystemInfoSource.linuxNativeCommand,
        SystemInfoSource.dartIoFallback,
      ],
      errors: errors,
      fieldSources: sources,
      fieldAttempts: fieldAttempts,
    );
  }

  Future<Map<String, Object?>> _linuxDartValues() async {
    final values = await _dartIoValues();
    final osRelease = await _readKeyValueFile('/etc/os-release');
    final prettyName = osRelease['PRETTY_NAME']?.replaceAll('"', '');
    if (_isUsable(prettyName)) values['operatingSystem'] = prettyName;

    final productName = await _readFirstExisting(<String>[
      '/sys/devices/virtual/dmi/id/product_name',
      '/sys/firmware/devicetree/base/model',
    ]);
    if (_isUsable(productName)) values['host'] = productName;

    final uptime = await File('/proc/uptime').readAsString();
    values['uptimeSeconds'] = double.tryParse(uptime.split(RegExp(r'\s+')).first)?.floor();

    final cpuInfo = await File('/proc/cpuinfo').readAsString();
    final cpuMatch = RegExp(r'^(?:model name|Hardware)\s*:\s*(.+)$', multiLine: true)
        .firstMatch(cpuInfo);
    if (cpuMatch != null) values['cpuModel'] = cpuMatch.group(1)?.trim();

    final memInfo = await _readKeyValueFile('/proc/meminfo', separator: ':');
    final totalKb = _leadingInt(memInfo['MemTotal']);
    final availableKb = _leadingInt(memInfo['MemAvailable']);
    if (totalKb != null) values['memoryTotalBytes'] = totalKb * 1024;
    if (totalKb != null && availableKb != null) {
      values['memoryUsedBytes'] = (totalKb - availableKb) * 1024;
    }
    return values;
  }

  Future<Map<String, Object?>> _linuxCommandValues() async {
    final values = <String, Object?>{};
    final uname = await Process.run('uname', const <String>['-sr']);
    if (uname.exitCode == 0) values['kernel'] = uname.stdout.toString().trim();
    final disk = await Process.run('df', const <String>['-B1', '--output=size,used', '/']);
    if (disk.exitCode == 0) {
      final lines = disk.stdout.toString().trim().split('\n');
      if (lines.length >= 2) {
        final parts = lines.last.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          values['diskTotalBytes'] = int.tryParse(parts[0]);
          values['diskUsedBytes'] = int.tryParse(parts[1]);
        }
      }
    }
    return values;
  }

  Future<SystemInfoSnapshot> _collectDartFallback() async {
    final stopwatch = Stopwatch()..start();
    final values = await _dartIoValues();
    stopwatch.stop();
    return _snapshotFromValues(
      values,
      platform: Platform.operatingSystem,
      primarySource: SystemInfoSource.dartIoFallback,
      elapsed: stopwatch.elapsed,
      attempts: const <SystemInfoSource>[SystemInfoSource.dartIoFallback],
      errors: const <String>[],
    );
  }

  Future<Map<String, Object?>> _dartIoValues() async {
    final values = <String, Object?>{
      'operatingSystem': Platform.operatingSystemVersion,
      'host': Platform.localHostname,
      'logicalProcessors': Platform.numberOfProcessors,
      'locale': Platform.localeName,
    };
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final addresses = <({int score, String address})>[];
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        final score = name.contains('wifi') || name.contains('wlan')
            ? 0
            : name.contains('eth') || name.startsWith('en')
                ? 1
                : 2;
        for (final address in interface.addresses) {
          if (!address.isLoopback && !address.address.startsWith('169.254.')) {
            addresses.add((score: score, address: address.address));
          }
        }
      }
      addresses.sort((a, b) => a.score.compareTo(b.score));
      if (addresses.isNotEmpty) values['localIp'] = addresses.first.address;
    } on SocketException {
      // Network information is optional.
    }
    return values;
  }

  SystemInfoSnapshot _snapshotFromValues(
    Map<String, Object?> values, {
    required String platform,
    required SystemInfoSource primarySource,
    required Duration elapsed,
    required List<SystemInfoSource> attempts,
    required List<String> errors,
    Map<SystemInfoField, SystemInfoSource>? fieldSources,
    Map<SystemInfoField, List<SystemInfoSource>>? fieldAttempts,
  }) {
    final diagnostics = <SystemInfoField, SystemInfoFieldDiagnostic>{};
    for (final field in SystemInfoField.values) {
      final value = values[field.wireName];
      final source = fieldSources?[field] ??
          (_isUsable(value) ? primarySource : SystemInfoSource.unavailable);
      diagnostics[field] = SystemInfoFieldDiagnostic(
        source: source,
        elapsed: elapsed,
        error: errors.isEmpty ? null : errors.join(' | '),
        attempts: List<SystemInfoSource>.unmodifiable(
          fieldAttempts?[field] ?? attempts,
        ),
      );
      if (_isUsable(value)) {
        _emit(
          SystemInfoLogLevel.debug,
          'Collected ${field.wireName}=${jsonEncode(value)}.',
          source,
          field: field,
          elapsed: elapsed,
        );
      }
    }
    return SystemInfoSnapshot(
      operatingSystem: _asString(values['operatingSystem']),
      host: _asString(values['host']),
      kernel: _asString(values['kernel']),
      uptime: _asInt(values['uptimeSeconds']) == null
          ? null
          : Duration(seconds: _asInt(values['uptimeSeconds'])!),
      cpuModel: _asString(values['cpuModel']),
      logicalProcessors: _asInt(values['logicalProcessors']),
      memoryUsedBytes: _asInt(values['memoryUsedBytes']),
      memoryTotalBytes: _asInt(values['memoryTotalBytes']),
      diskUsedBytes: _asInt(values['diskUsedBytes']),
      diskTotalBytes: _asInt(values['diskTotalBytes']),
      localIp: _asString(values['localIp']),
      locale: _asString(values['locale']),
      diagnostics: SystemInfoDiagnostics(
        platform: platform,
        primarySource: primarySource,
        totalElapsed: elapsed,
        fields: diagnostics,
        logs: List<String>.unmodifiable(errors),
      ),
    );
  }

  void _merge(
    Map<String, Object?> destination,
    Map<SystemInfoField, SystemInfoSource> sources,
    Map<String, Object?> incoming,
    SystemInfoSource source,
  ) {
    for (final field in SystemInfoField.values) {
      if (_isUsable(destination[field.wireName])) continue;
      final value = incoming[field.wireName];
      if (!_isUsable(value)) continue;
      destination[field.wireName] = value;
      sources[field] = source;
    }
  }

  void _recordAttempts(
    Map<SystemInfoField, List<SystemInfoSource>> destination,
    Iterable<SystemInfoField> fields,
    SystemInfoSource source,
  ) {
    for (final field in fields) {
      final attempts = destination.putIfAbsent(
        field,
        () => <SystemInfoSource>[],
      );
      if (!attempts.contains(source)) attempts.add(source);
    }
  }

  List<SystemInfoField> _missingFields(Map<String, Object?> values) =>
      SystemInfoField.values
          .where((field) => !_isUsable(values[field.wireName]))
          .toList();

  void _notifyFields(SystemInfoSnapshot snapshot, SystemInfoFieldListener? listener) {
    if (listener == null) return;
    for (final field in SystemInfoField.values) {
      final value = snapshot.valueFor(field);
      final diagnostic = snapshot.diagnostics.fields[field];
      if (value != null && diagnostic != null) listener(field, value, diagnostic);
    }
  }

  SystemInfoSnapshot _withCacheDiagnostics(SystemInfoSnapshot snapshot) {
    final fields = <SystemInfoField, SystemInfoFieldDiagnostic>{
      for (final field in SystemInfoField.values)
        field: SystemInfoFieldDiagnostic(
          source: SystemInfoSource.cache,
          attempts: const <SystemInfoSource>[SystemInfoSource.cache],
        ),
    };
    return SystemInfoSnapshot(
      operatingSystem: snapshot.operatingSystem,
      host: snapshot.host,
      kernel: snapshot.kernel,
      uptime: snapshot.uptime,
      cpuModel: snapshot.cpuModel,
      logicalProcessors: snapshot.logicalProcessors,
      memoryUsedBytes: snapshot.memoryUsedBytes,
      memoryTotalBytes: snapshot.memoryTotalBytes,
      diskUsedBytes: snapshot.diskUsedBytes,
      diskTotalBytes: snapshot.diskTotalBytes,
      localIp: snapshot.localIp,
      locale: snapshot.locale,
      diagnostics: SystemInfoDiagnostics(
        platform: snapshot.diagnostics.platform,
        primarySource: SystemInfoSource.cache,
        totalElapsed: Duration.zero,
        fields: fields,
        logs: const <String>['Returned from in-memory cache.'],
      ),
    );
  }

  void _emit(
    SystemInfoLogLevel level,
    String message,
    SystemInfoSource source, {
    SystemInfoField? field,
    Duration elapsed = Duration.zero,
  }) {
    onEvent?.call(SystemInfoEvent(
      level: level,
      message: message,
      source: source,
      field: field,
      elapsed: elapsed,
    ));
  }

  static bool _isUsable(Object? value) =>
      value != null && (value is! String || value.trim().isNotEmpty);
  static String? _asString(Object? value) =>
      _isUsable(value) ? value.toString().trim() : null;
  static int? _asInt(Object? value) => value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');

  static int? _leadingInt(String? value) {
    if (value == null) return null;
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static Future<Map<String, String>> _readKeyValueFile(
    String path, {
    String separator = '=',
  }) async {
    final result = <String, String>{};
    for (final line in await File(path).readAsLines()) {
      final index = line.indexOf(separator);
      if (index <= 0) continue;
      result[line.substring(0, index).trim()] = line.substring(index + 1).trim();
    }
    return result;
  }

  static Future<String?> _readFirstExisting(List<String> paths) async {
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final value = (await file.readAsString()).replaceAll('\u0000', '').trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}
