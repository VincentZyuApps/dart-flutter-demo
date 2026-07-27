import 'package:dart_flutter_demo/services/system_info_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_info_vincentzyu/system_info_vincentzyu.dart';

void main() {
  test('formats typed bytes, uptime, and processor count in the App layer', () {
    const snapshot = SystemInfoSnapshot(
      operatingSystem: 'Example OS',
      host: 'Example Host',
      kernel: 'Example Kernel',
      uptime: Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
      cpuModel: 'Example CPU',
      logicalProcessors: 8,
      memoryUsedBytes: 4 * 1024 * 1024 * 1024,
      memoryTotalBytes: 8 * 1024 * 1024 * 1024,
      diskUsedBytes: 128 * 1024 * 1024 * 1024,
      diskTotalBytes: 256 * 1024 * 1024 * 1024,
      localIp: '192.168.1.2',
      locale: 'en-US',
      diagnostics: SystemInfoDiagnostics.empty(),
    );

    final values = SystemInfoFormatter.format(snapshot);
    expect(values['Uptime'], '1 days, 2 hours, 3 mins, 4 secs');
    expect(values['CPU'], 'Example CPU (8 logical processors)');
    expect(values['Memory'], '4.00 GiB / 8.00 GiB (50%)');
    expect(values.values, contains('128.00 GiB / 256.00 GiB (50%)'));
  });
}
