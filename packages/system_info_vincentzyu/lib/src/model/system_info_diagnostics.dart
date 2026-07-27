import 'system_info_field.dart';
import 'system_info_source.dart';

class SystemInfoFieldDiagnostic {
  final SystemInfoSource source;
  final Duration elapsed;
  final String? error;
  final List<SystemInfoSource> attempts;

  const SystemInfoFieldDiagnostic({
    required this.source,
    this.elapsed = Duration.zero,
    this.error,
    this.attempts = const <SystemInfoSource>[],
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'source': source.name,
        'elapsedMicros': elapsed.inMicroseconds,
        if (error != null) 'error': error,
        'attempts': attempts.map((value) => value.name).toList(),
      };
}

class SystemInfoDiagnostics {
  final String platform;
  final SystemInfoSource primarySource;
  final Duration totalElapsed;
  final Map<SystemInfoField, SystemInfoFieldDiagnostic> fields;
  final List<String> logs;

  const SystemInfoDiagnostics({
    required this.platform,
    required this.primarySource,
    required this.totalElapsed,
    required this.fields,
    required this.logs,
  });

  const SystemInfoDiagnostics.empty()
      : platform = 'unknown',
        primarySource = SystemInfoSource.unavailable,
        totalElapsed = Duration.zero,
        fields = const <SystemInfoField, SystemInfoFieldDiagnostic>{},
        logs = const <String>[];

  Map<String, Object?> toJson() => <String, Object?>{
        'platform': platform,
        'primarySource': primarySource.name,
        'totalMicros': totalElapsed.inMicroseconds,
        'fields': <String, Object?>{
          for (final entry in fields.entries)
            entry.key.wireName: entry.value.toJson(),
        },
        'logs': logs,
      };
}
