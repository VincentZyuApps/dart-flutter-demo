import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:system_info_vincentzyu/system_info_vincentzyu.dart';

abstract class SystemInfoService {
  SystemInfoSnapshot? get latestSnapshot;

  Future<Map<String, String>> getInfo({
    bool forceRefresh = false,
    void Function(String key, String value)? onField,
  });
}

class SystemInfoDebugSnapshot {
  const SystemInfoDebugSnapshot({
    required this.platform,
    required this.source,
    required this.ffiStatus,
    required this.logs,
    required this.data,
    required this.fieldDiagnostics,
    this.logFilePath,
  });

  final String platform;
  final String source;
  final String ffiStatus;
  final List<String> logs;
  final Map<String, String> data;
  final Map<String, String> fieldDiagnostics;
  final String? logFilePath;

  String toMultilineText() {
    final buffer = StringBuffer()
      ..writeln('platform: $platform')
      ..writeln('source: $source')
      ..writeln('ffi_status: $ffiStatus')
      ..writeln('live_log: ${logFilePath ?? 'unavailable'}')
      ..writeln()
      ..writeln('[data]');
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer
      ..writeln()
      ..writeln('[field_diagnostics]');
    for (final entry in fieldDiagnostics.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer
      ..writeln()
      ..writeln('[logs]');
    for (final line in logs) {
      buffer.writeln(line);
    }
    return buffer.toString();
  }
}

final _SystemInfoAppService _systemInfoService = _SystemInfoAppService();

SystemInfoService createSystemInfoService() => _systemInfoService;

SystemInfoDebugSnapshot getSystemInfoDebugSnapshot() =>
    _systemInfoService.debugSnapshot;

Future<File> exportSystemInfoDebugSnapshot() =>
    _systemInfoService.exportDebugSnapshot();

Future<int> copySystemInfoDebugSnapshotToClipboard({
  int maxChars = 240000,
}) async {
  final text = getSystemInfoDebugSnapshot().toMultilineText();
  final clipped = text.length <= maxChars
      ? text
      : text.substring(text.length - maxChars);
  await Clipboard.setData(ClipboardData(text: clipped));
  return clipped.length;
}

class _SystemInfoAppService implements SystemInfoService {
  SystemInfoClient? _client;
  SystemInfoSessionLogSink? _logSink;
  Future<void>? _initializing;
  SystemInfoSnapshot? _snapshot;
  Map<String, String> _formatted = const <String, String>{};

  @override
  SystemInfoSnapshot? get latestSnapshot => _snapshot;

  SystemInfoDebugSnapshot get debugSnapshot {
    final snapshot = _snapshot;
    final diagnostics = snapshot?.diagnostics;
    final fields = <String, String>{};
    for (final entry in diagnostics?.fields.entries ??
        const <MapEntry<SystemInfoField, SystemInfoFieldDiagnostic>>[]) {
      final value = entry.value;
      fields[entry.key.wireName] =
          'source=${value.source.name}, elapsed=${_formatElapsed(value.elapsed)}, '
          'attempts=${value.attempts.map((item) => item.name).join(' -> ')}'
          '${value.error == null ? '' : ', error=${value.error}'}';
    }
    final events = _logSink?.memoryEvents ?? const <SystemInfoEvent>[];
    return SystemInfoDebugSnapshot(
      platform: diagnostics?.platform ?? Platform.operatingSystem,
      source: diagnostics?.primarySource.name ?? 'idle',
      ffiStatus: _ffiStatus(diagnostics),
      logs: events.map(_eventText).toList(growable: false),
      data: Map<String, String>.from(_formatted),
      fieldDiagnostics: fields,
      logFilePath: _logSink?.currentFile?.path,
    );
  }

  @override
  Future<Map<String, String>> getInfo({
    bool forceRefresh = false,
    void Function(String key, String value)? onField,
  }) async {
    await _ensureInitialized();
    final snapshot = await _client!.collect(forceRefresh: forceRefresh);
    _snapshot = snapshot;
    _formatted = SystemInfoFormatter.format(snapshot);
    for (final entry in _formatted.entries) {
      onField?.call(entry.key, entry.value);
    }
    return Map<String, String>.from(_formatted);
  }

  Future<File> exportDebugSnapshot() async {
    await _ensureInitialized();
    await _logSink!.flush();
    Directory directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = Directory.systemTemp;
    }
    final exportDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}DartFlutterDemo',
    );
    await exportDirectory.create(recursive: true);
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}'
      'dart_flutter_demo_system_info_export_${_fileTimestamp(DateTime.now())}.log',
    );
    await file.writeAsString(debugSnapshot.toMultilineText(), flush: true);
    return file;
  }

  Future<void> _ensureInitialized() {
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    Directory root;
    try {
      root = await getApplicationSupportDirectory();
    } catch (_) {
      root = Directory.systemTemp;
    }
    final sink = SystemInfoSessionLogSink(
      directory: Directory(
        '${root.path}${Platform.pathSeparator}DartFlutterDemo'
        '${Platform.pathSeparator}logs',
      ),
      filePrefix: 'dart_flutter_demo_system_info',
    );
    await sink.open();
    _logSink = sink;
    _client = SystemInfoClient(onEvent: sink.add);
    sink.add(SystemInfoEvent(
      level: SystemInfoLogLevel.info,
      message: 'System information session initialized.',
      source: SystemInfoSource.dartIoFallback,
    ));
  }

  static String _ffiStatus(SystemInfoDiagnostics? diagnostics) {
    if (!Platform.isWindows) return 'n/a';
    if (diagnostics == null) return 'idle';
    if (diagnostics.primarySource == SystemInfoSource.windowsFfi) return 'active';
    final attempted = diagnostics.fields.values.any(
      (field) => field.attempts.contains(SystemInfoSource.windowsFfi),
    );
    return attempted ? 'fallback' : 'not-attempted';
  }

  static String _eventText(SystemInfoEvent event) {
    final field = event.field == null ? '' : ' field=${event.field!.wireName}';
    return '[${event.timestampUtc.toLocal().toIso8601String()}] '
        '${event.level.name.toUpperCase()} source=${event.source.name}$field '
        'elapsed=${_formatElapsed(event.elapsed)} ${event.message}';
  }

  static String _formatElapsed(Duration value) {
    if (value.inMilliseconds > 0) return '${value.inMilliseconds} ms';
    return '${value.inMicroseconds} us';
  }

  static String _fileTimestamp(DateTime value) {
    String two(int part) => part.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}

class SystemInfoFormatter {
  const SystemInfoFormatter._();

  static Map<String, String> format(SystemInfoSnapshot snapshot) {
    final cpu = <String>[
      if (_usable(snapshot.cpuModel)) snapshot.cpuModel!,
      if (snapshot.logicalProcessors != null)
        '(${snapshot.logicalProcessors} logical processors)',
    ].join(' ');
    return <String, String>{
      'OS': _text(snapshot.operatingSystem),
      'Host': _text(snapshot.host),
      'Kernel': _text(snapshot.kernel),
      'Uptime': _duration(snapshot.uptime),
      'CPU': cpu.isEmpty ? 'unavailable' : cpu,
      'Memory': _usage(snapshot.memoryUsedBytes, snapshot.memoryTotalBytes),
      _diskLabel: _usage(snapshot.diskUsedBytes, snapshot.diskTotalBytes),
      'Local IP': _text(snapshot.localIp),
      'Locale': _text(snapshot.locale),
    };
  }

  static String get _diskLabel {
    if (Platform.isWindows) return r'Disk (C:\)';
    if (Platform.isLinux || Platform.isMacOS) return 'Disk (/)';
    return 'Disk';
  }

  static String _text(String? value) => _usable(value) ? value!.trim() : 'unavailable';

  static String _duration(Duration? value) {
    if (value == null) return 'unavailable';
    final days = value.inDays;
    final hours = value.inHours.remainder(24);
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return <String>[
      if (days > 0) '$days days',
      '$hours hours',
      '$minutes mins',
      '$seconds secs',
    ].join(', ');
  }

  static String _usage(int? used, int? total) {
    if (used == null || total == null || total <= 0) return 'unavailable';
    final percent = (used * 100 / total).clamp(0, 100).round();
    return '${_bytes(used)} / ${_bytes(total)} ($percent%)';
  }

  static String _bytes(int bytes) {
    const gib = 1024 * 1024 * 1024;
    const mib = 1024 * 1024;
    if (bytes >= gib) return '${(bytes / gib).toStringAsFixed(2)} GiB';
    return '${(bytes / mib).toStringAsFixed(2)} MiB';
  }

  static bool _usable(String? value) => value != null && value.trim().isNotEmpty;
}
