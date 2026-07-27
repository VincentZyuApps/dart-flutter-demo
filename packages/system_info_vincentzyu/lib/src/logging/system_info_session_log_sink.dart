import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../model/system_info_event.dart';
import '../model/system_info_field.dart';

class SystemInfoSessionLogSink {
  SystemInfoSessionLogSink({
    required this.directory,
    this.filePrefix = 'system_info_vincentzyu',
    this.maxFileBytes = 10 * 1024 * 1024,
    this.maxFiles = 5,
    this.maxMemoryEvents = 2000,
  });

  final Directory directory;
  final String filePrefix;
  final int maxFileBytes;
  final int maxFiles;
  final int maxMemoryEvents;

  final List<SystemInfoEvent> _events = <SystemInfoEvent>[];
  final StreamController<SystemInfoEvent> _controller =
      StreamController<SystemInfoEvent>.broadcast(sync: true);
  Future<void> _writeQueue = Future<void>.value();
  File? _file;
  DateTime? _sessionStarted;
  int _part = 0;
  bool _closed = false;

  Stream<SystemInfoEvent> get events => _controller.stream;
  List<SystemInfoEvent> get memoryEvents =>
      List<SystemInfoEvent>.unmodifiable(_events);
  File? get currentFile => _file;

  Future<File> open() async {
    if (_closed) throw StateError('The log sink is closed.');
    if (_file != null) return _file!;
    await directory.create(recursive: true);
    _sessionStarted = DateTime.now();
    _file = await _createPart();
    return _file!;
  }

  void add(SystemInfoEvent event) {
    if (_closed) return;
    _events.add(event);
    if (_events.length > maxMemoryEvents) {
      _events.removeRange(0, _events.length - maxMemoryEvents);
    }
    _controller.add(event);

    if (!kReleaseMode ||
        event.level == SystemInfoLogLevel.warning ||
        event.level == SystemInfoLogLevel.error) {
      debugPrint(_formatLine(event).trimRight());
    }

    _writeQueue = _writeQueue.then((_) => _append(event)).catchError((Object e) {
      debugPrint('system_info log write failed: $e');
    });
  }

  Future<void> flush() => _writeQueue;

  Future<void> close() async {
    if (_closed) return;
    await flush();
    _closed = true;
    await _controller.close();
  }

  Future<void> _append(SystemInfoEvent event) async {
    var file = await open();
    final line = _formatLine(event);
    final currentBytes = await file.length();
    if (currentBytes > 0 &&
        currentBytes + utf8.encode(line).length > maxFileBytes) {
      file = await _createPart();
    }
    await file.writeAsString(line, mode: FileMode.append, flush: true);
  }

  Future<File> _createPart() async {
    _part += 1;
    final started = _sessionStarted ?? DateTime.now();
    final partSuffix =
        _part == 1 ? '' : '_part${_part.toString().padLeft(2, '0')}';
    var collision = 1;
    late File file;
    do {
      final collisionSuffix =
          collision == 1 ? '' : '_${collision.toString().padLeft(2, '0')}';
      file = File(
        '${directory.path}${Platform.pathSeparator}'
        '${filePrefix}_${_fileTimestamp(started)}'
        '$partSuffix$collisionSuffix.log',
      );
      collision += 1;
    } while (await file.exists());
    final local = _isoLocal(started);
    final utc = started.toUtc().toIso8601String();
    await file.writeAsString(
      '# system_info_vincentzyu session log\n'
      '# session_started_local: $local\n'
      '# session_started_utc: $utc\n'
      '# privacy: may contain hostname and local IP; no automatic upload\n',
      flush: true,
    );
    _file = file;
    await _pruneOldFiles();
    return file;
  }

  Future<void> _pruneOldFiles() async {
    final files = await directory
        .list()
        .where((entry) =>
            entry is File &&
            entry.path
                .split(Platform.pathSeparator)
                .last
                .startsWith(filePrefix) &&
            entry.path.endsWith('.log'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    for (final file in files.skip(maxFiles)) {
      try {
        await file.delete();
      } on FileSystemException {
        // Logging must never break system information collection.
      }
    }
  }

  String _formatLine(SystemInfoEvent event) {
    final field = event.field == null ? '' : ' field=${event.field!.wireName}';
    return '${_isoLocal(event.timestampUtc.toLocal())} '
        '[${event.level.name.toUpperCase()}] '
        'source=${event.source.name}$field '
        'elapsed_us=${event.elapsed.inMicroseconds} ${event.message}\n';
  }

  static String _fileTimestamp(DateTime value) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  static String _isoLocal(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    String three(int part) => part.toString().padLeft(3, '0');
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final base = '${local.year}-${two(local.month)}-${two(local.day)}T'
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}.'
        '${three(local.millisecond)}';
    return '$base$sign$hours:$minutes';
  }
}
