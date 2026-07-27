import 'system_info_diagnostics.dart';
import 'system_info_field.dart';

class SystemInfoSnapshot {
  final String? operatingSystem;
  final String? host;
  final String? kernel;
  final Duration? uptime;
  final String? cpuModel;
  final int? logicalProcessors;
  final int? memoryUsedBytes;
  final int? memoryTotalBytes;
  final int? diskUsedBytes;
  final int? diskTotalBytes;
  final String? localIp;
  final String? locale;
  final SystemInfoDiagnostics diagnostics;

  const SystemInfoSnapshot({
    this.operatingSystem,
    this.host,
    this.kernel,
    this.uptime,
    this.cpuModel,
    this.logicalProcessors,
    this.memoryUsedBytes,
    this.memoryTotalBytes,
    this.diskUsedBytes,
    this.diskTotalBytes,
    this.localIp,
    this.locale,
    required this.diagnostics,
  });

  double? get memoryUsedPercent => _percent(memoryUsedBytes, memoryTotalBytes);
  double? get diskUsedPercent => _percent(diskUsedBytes, diskTotalBytes);

  Map<String, Object?> toJson() => <String, Object?>{
        'operatingSystem': operatingSystem,
        'host': host,
        'kernel': kernel,
        'uptimeSeconds': uptime?.inSeconds,
        'cpuModel': cpuModel,
        'logicalProcessors': logicalProcessors,
        'memoryUsedBytes': memoryUsedBytes,
        'memoryTotalBytes': memoryTotalBytes,
        'diskUsedBytes': diskUsedBytes,
        'diskTotalBytes': diskTotalBytes,
        'localIp': localIp,
        'locale': locale,
        'diagnostics': diagnostics.toJson(),
      };

  Object? valueFor(SystemInfoField field) => switch (field) {
        SystemInfoField.operatingSystem => operatingSystem,
        SystemInfoField.host => host,
        SystemInfoField.kernel => kernel,
        SystemInfoField.uptime => uptime,
        SystemInfoField.cpuModel => cpuModel,
        SystemInfoField.logicalProcessors => logicalProcessors,
        SystemInfoField.memoryUsedBytes => memoryUsedBytes,
        SystemInfoField.memoryTotalBytes => memoryTotalBytes,
        SystemInfoField.diskUsedBytes => diskUsedBytes,
        SystemInfoField.diskTotalBytes => diskTotalBytes,
        SystemInfoField.localIp => localIp,
        SystemInfoField.locale => locale,
      };

  static double? _percent(int? used, int? total) {
    if (used == null || total == null || total <= 0) return null;
    return used * 100 / total;
  }
}
