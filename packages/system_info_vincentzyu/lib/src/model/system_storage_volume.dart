enum SystemStorageScope { hostVisible, appVisible }

/// A filesystem capacity view that the current process can inspect.
///
/// Sandboxed mobile and Flatpak builds deliberately report only storage made
/// visible to the application. They never claim to enumerate the whole host.
class SystemStorageVolume {
  final String mountPoint;
  final String? volumeLabel;
  final int usedBytes;
  final int totalBytes;
  final String? fileSystem;
  final String? device;
  final SystemStorageScope scope;

  const SystemStorageVolume({
    required this.mountPoint,
    required this.usedBytes,
    required this.totalBytes,
    this.volumeLabel,
    this.fileSystem,
    this.device,
    this.scope = SystemStorageScope.hostVisible,
  });

  double? get usedPercent => totalBytes <= 0 ? null : usedBytes * 100 / totalBytes;

  Map<String, Object?> toJson() => <String, Object?>{
        'mountPoint': mountPoint,
        if (volumeLabel != null) 'volumeLabel': volumeLabel,
        'usedBytes': usedBytes,
        'totalBytes': totalBytes,
        if (fileSystem != null) 'fileSystem': fileSystem,
        if (device != null) 'device': device,
        'scope': scope.name,
      };

  static SystemStorageVolume? fromJson(Object? value) {
    if (value is! Map) return null;
    final mountPoint = value['mountPoint']?.toString().trim();
    final usedBytes = _asInt(value['usedBytes']);
    final totalBytes = _asInt(value['totalBytes']);
    if (mountPoint == null || mountPoint.isEmpty || usedBytes == null ||
        totalBytes == null || totalBytes <= 0) {
      return null;
    }
    String? text(String key) {
      final result = value[key]?.toString().trim();
      return result == null || result.isEmpty ? null : result;
    }

    return SystemStorageVolume(
      mountPoint: mountPoint,
      volumeLabel: text('volumeLabel'),
      usedBytes: usedBytes.clamp(0, totalBytes).toInt(),
      totalBytes: totalBytes,
      fileSystem: text('fileSystem'),
      device: text('device'),
      scope: value['scope'] == SystemStorageScope.appVisible.name
          ? SystemStorageScope.appVisible
          : SystemStorageScope.hostVisible,
    );
  }

  static int? _asInt(Object? value) => value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');
}
