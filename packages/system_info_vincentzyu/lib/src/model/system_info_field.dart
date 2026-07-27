enum SystemInfoField {
  operatingSystem,
  host,
  kernel,
  uptime,
  cpuModel,
  logicalProcessors,
  memoryUsedBytes,
  memoryTotalBytes,
  diskUsedBytes,
  diskTotalBytes,
  localIp,
  locale,
}

extension SystemInfoFieldName on SystemInfoField {
  String get wireName => switch (this) {
        SystemInfoField.operatingSystem => 'operatingSystem',
        SystemInfoField.host => 'host',
        SystemInfoField.kernel => 'kernel',
        SystemInfoField.uptime => 'uptimeSeconds',
        SystemInfoField.cpuModel => 'cpuModel',
        SystemInfoField.logicalProcessors => 'logicalProcessors',
        SystemInfoField.memoryUsedBytes => 'memoryUsedBytes',
        SystemInfoField.memoryTotalBytes => 'memoryTotalBytes',
        SystemInfoField.diskUsedBytes => 'diskUsedBytes',
        SystemInfoField.diskTotalBytes => 'diskTotalBytes',
        SystemInfoField.localIp => 'localIp',
        SystemInfoField.locale => 'locale',
      };

  static SystemInfoField? fromWireName(String value) {
    for (final field in SystemInfoField.values) {
      if (field.wireName == value) return field;
    }
    return null;
  }
}
