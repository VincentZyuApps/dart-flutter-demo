import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:system_info_vincentzyu/system_info_vincentzyu.dart';

void main() {
  test('typed snapshot calculates percentages', () {
    const snapshot = SystemInfoSnapshot(
      memoryUsedBytes: 25,
      memoryTotalBytes: 100,
      diskUsedBytes: 3,
      diskTotalBytes: 4,
      diagnostics: SystemInfoDiagnostics.empty(),
    );
    expect(snapshot.memoryUsedPercent, 25);
    expect(snapshot.diskUsedPercent, 75);
  });

  test('field diagnostics serialize source, timing, attempts, and error', () {
    const diagnostic = SystemInfoFieldDiagnostic(
      source: SystemInfoSource.windowsFfi,
      elapsed: Duration(microseconds: 42),
      attempts: <SystemInfoSource>[
        SystemInfoSource.windowsFfi,
        SystemInfoSource.windowsNativeCommand,
      ],
      error: 'example',
    );
    expect(diagnostic.toJson(), <String, Object?>{
      'source': 'windowsFfi',
      'elapsedMicros': 42,
      'error': 'example',
      'attempts': <String>['windowsFfi', 'windowsNativeCommand'],
    });
  });

  test('session log rotates and retains the configured file count', () async {
    final directory = await Directory.systemTemp.createTemp('system_info_log_test_');
    addTearDown(() => directory.delete(recursive: true));
    final sink = SystemInfoSessionLogSink(
      directory: directory,
      maxFileBytes: 320,
      maxFiles: 2,
    );
    await sink.open();
    for (var index = 0; index < 20; index += 1) {
      sink.add(SystemInfoEvent(
        level: SystemInfoLogLevel.info,
        message: 'rotation event $index with enough text to rotate the log file',
        source: SystemInfoSource.linuxDartIo,
      ));
    }
    await sink.flush();
    final files = await directory
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    expect(files.length, 2);
    expect(files.every((file) => file.path.endsWith('.log')), isTrue);
    await sink.close();
  });
}
