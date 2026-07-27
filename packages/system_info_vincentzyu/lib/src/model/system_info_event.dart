import 'system_info_field.dart';
import 'system_info_source.dart';

enum SystemInfoLogLevel { debug, info, warning, error }

class SystemInfoEvent {
  final DateTime timestampUtc;
  final SystemInfoLogLevel level;
  final String message;
  final SystemInfoSource source;
  final SystemInfoField? field;
  final Duration elapsed;

  SystemInfoEvent({
    DateTime? timestampUtc,
    required this.level,
    required this.message,
    required this.source,
    this.field,
    this.elapsed = Duration.zero,
  }) : timestampUtc = (timestampUtc ?? DateTime.now()).toUtc();

  Map<String, Object?> toJson() => <String, Object?>{
        'timestampUtc': timestampUtc.toIso8601String(),
        'level': level.name,
        'source': source.name,
        if (field != null) 'field': field!.wireName,
        'elapsedMicros': elapsed.inMicroseconds,
        'message': message,
      };
}
