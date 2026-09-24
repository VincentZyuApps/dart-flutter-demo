import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:package_info_plus/package_info_plus.dart';

import 'system_info_service.dart';

enum CommandLineMode {
  gui,
  help,
  version,
  systemInfoText,
  systemInfoJson,
  logDirectory,
  listLogs,
  exportLogs,
  clearLogs,
}

/// A parsed, non-GUI command line request.
class CommandLineRequest {
  const CommandLineRequest({
    required this.mode,
    this.includeSensitive = false,
    this.assumeYes = false,
    this.exportPath,
    this.error,
  });

  final CommandLineMode mode;
  final bool includeSensitive;
  final bool assumeYes;
  final String? exportPath;
  final String? error;

  bool get isCommand => mode != CommandLineMode.gui;
  bool get hasError => error != null;

  static CommandLineRequest parse(List<String> arguments) {
    CommandLineMode mode = CommandLineMode.gui;
    String? exportPath;
    var includeSensitive = false;
    var assumeYes = false;
    var hasGuiOption = false;

    CommandLineRequest invalid(String message) => CommandLineRequest(
          mode: mode,
          includeSensitive: includeSensitive,
          assumeYes: assumeYes,
          exportPath: exportPath,
          error: message,
        );

    bool select(CommandLineMode next) {
      if (hasGuiOption || (mode != CommandLineMode.gui && mode != next)) {
        return false;
      }
      mode = next;
      return true;
    }

    for (var index = 0; index < arguments.length; index++) {
      final String argument = arguments[index];
      switch (argument) {
        case '--help':
        case '-h':
          if (!select(CommandLineMode.help)) return invalid('Only one command is allowed.');
          break;
        case '--version':
        case '-V':
          if (!select(CommandLineMode.version)) return invalid('Only one command is allowed.');
          break;
        case '--system-info':
          if (!select(CommandLineMode.systemInfoText)) return invalid('Only one command is allowed.');
          break;
        case '--system-info=json':
          if (!select(CommandLineMode.systemInfoJson)) return invalid('Only one command is allowed.');
          break;
        case '--include-sensitive':
          includeSensitive = true;
          break;
        case '--log-dir':
          if (!select(CommandLineMode.logDirectory)) return invalid('Only one command is allowed.');
          break;
        case '--list-logs':
          if (!select(CommandLineMode.listLogs)) return invalid('Only one command is allowed.');
          break;
        case '--export-logs':
          if (!select(CommandLineMode.exportLogs)) return invalid('Only one command is allowed.');
          if (index + 1 >= arguments.length || arguments[index + 1].startsWith('-')) {
            return invalid('--export-logs requires a target .zip path.');
          }
          exportPath = arguments[++index];
          break;
        case '--clear-logs':
          if (!select(CommandLineMode.clearLogs)) return invalid('Only one command is allowed.');
          break;
        case '--yes':
          assumeYes = true;
          break;
        default:
          if (argument.startsWith('--tab=') || argument.startsWith('--action=')) {
            if (mode != CommandLineMode.gui) {
              return invalid('GUI routes cannot be combined with a command.');
            }
            hasGuiOption = true;
          } else if (argument.startsWith('--kde-wayland-focus=')) {
            if (mode != CommandLineMode.gui) {
              return invalid('GUI options cannot be combined with a command.');
            }
            final String value = argument.substring('--kde-wayland-focus='.length);
            if (value != 'safe' && value != 'mpris' && value != 'all') {
              return invalid('Invalid KDE Wayland focus policy: $value.');
            }
            hasGuiOption = true;
          } else if (argument.startsWith('-')) {
            return invalid('Unknown option: $argument');
          }
      }
    }
    if (includeSensitive &&
        mode != CommandLineMode.systemInfoText &&
        mode != CommandLineMode.systemInfoJson) {
      return invalid('--include-sensitive requires --system-info.');
    }
    if (assumeYes &&
        mode != CommandLineMode.exportLogs && mode != CommandLineMode.clearLogs) {
      return invalid('--yes requires --export-logs or --clear-logs.');
    }
    return CommandLineRequest(
      mode: mode,
      includeSensitive: includeSensitive,
      assumeYes: assumeYes,
      exportPath: exportPath,
    );
  }
}

/// Runs non-GUI maintenance commands without creating an application window.
class CommandLineService {
  CommandLineService._();

  static const String usage = '''DartFlutterDemo command line

Usage: dart_flutter_demo [command] [options]

Commands:
  -h, --help                         Show this help and exit.
  -V, --version                      Print the full application version.
      --system-info[=json]           Print system information as text or JSON.
      --log-dir                      Print the session-log directory without creating it.
      --list-logs                    List existing session logs without creating one.
      --export-logs <target.zip>     Export existing session logs and a manifest.
      --clear-logs                   Delete existing session logs.

Options:
      --include-sensitive            Include hostname and local IP in --system-info output.
      --yes                          Skip the export or deletion confirmation prompt.
      --kde-wayland-focus=safe|mpris|all
                                      GUI only. safe is the default. mpris permits only
                                      MPRIS Play/Raise to ask KWin to focus the window;
                                      all permits every tokenless restore request.
                                      mpris and all deliberately bypass KWin's focus-stealing
                                      protection and require explicit user opt-in.
''';

  static Future<int> run(CommandLineRequest request) async {
    switch (request.mode) {
      case CommandLineMode.gui:
        return 0;
      case CommandLineMode.help:
        stdout.write(usage);
        return 0;
      case CommandLineMode.version:
        final PackageInfo package = await PackageInfo.fromPlatform();
        stdout.writeln(package.version);
        return 0;
      case CommandLineMode.systemInfoText:
      case CommandLineMode.systemInfoJson:
        return _printSystemInfo(request);
      case CommandLineMode.logDirectory:
        stdout.writeln((await getSystemInfoLogDirectory()).path);
        return 0;
      case CommandLineMode.listLogs:
        return _listLogs();
      case CommandLineMode.exportLogs:
        return _exportLogs(request);
      case CommandLineMode.clearLogs:
        return _clearLogs(request);
    }
  }

  static Future<int> _printSystemInfo(CommandLineRequest request) async {
    final SystemInfoService service = createSystemInfoService();
    final Map<String, String> data = await service.getInfo();
    final Map<String, String> visible = _redact(data, request.includeSensitive);
    if (request.mode == CommandLineMode.systemInfoText) {
      final List<MapEntry<String, String>> entries = visible.entries.toList()
        ..sort((MapEntry<String, String> a, MapEntry<String, String> b) =>
            a.key.compareTo(b.key));
      for (final MapEntry<String, String> entry in entries) {
        stdout.writeln('${entry.key}: ${entry.value}');
      }
      return 0;
    }
    final Map<String, Object?> result = <String, Object?>{'data': visible};
    final snapshot = service.latestSnapshot;
    if (snapshot != null) {
      final Map<String, Object?> raw = Map<String, Object?>.from(snapshot.toJson());
      if (!request.includeSensitive) {
        raw.remove('host');
        raw.remove('localIp');
      }
      result['raw'] = raw;
    }
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
    return 0;
  }

  static Map<String, String> _redact(
    Map<String, String> data,
    bool includeSensitive,
  ) {
    if (includeSensitive) return Map<String, String>.from(data);
    final Map<String, String> result = Map<String, String>.from(data);
    result.remove('Host');
    result.remove('Local IP');
    return result;
  }

  static Future<int> _listLogs() async {
    final List<File> files = await listSystemInfoLogFiles();
    for (final File file in files) {
      stdout.writeln(file.path);
    }
    return 0;
  }

  static Future<int> _exportLogs(CommandLineRequest request) async {
    final bool? confirmed = await _confirm(
      request,
      'Exporting logs can include device information. Continue? [y/N] ',
    );
    if (confirmed == null) {
      return 64;
    }
    if (!confirmed) {
      return 0;
    }
    final List<File> files = await listSystemInfoLogFiles();
    if (files.isEmpty) {
      stderr.writeln('No session logs are available to export.');
      return 1;
    }
    final File target = File(request.exportPath!).absolute;
    if (target.path.toLowerCase().endsWith('.zip') == false) {
      stderr.writeln('The export target must end with .zip.');
      return 64;
    }
    if (await target.exists()) {
      stderr.writeln('Refusing to overwrite an existing file: ${target.path}');
      return 1;
    }
    if (!await target.parent.exists()) {
      stderr.writeln('The export directory does not exist: ${target.parent.path}');
      return 1;
    }
    final _ZipArchive archive = _ZipArchive();
    final List<String> names = <String>[];
    for (final File file in files) {
      final String name = file.uri.pathSegments.last;
      names.add(name);
      archive.addFile('logs/$name', await file.readAsBytes(), await file.lastModified());
    }
    final PackageInfo package = await PackageInfo.fromPlatform();
    archive.addFile(
      'manifest.json',
      utf8.encode(const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'application': 'DartFlutterDemo',
        'version': package.version,
        'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'privacy': 'Logs may contain hostname and local IP. They are never uploaded automatically.',
        'files': names,
      })),
      DateTime.now(),
    );
    await target.writeAsBytes(archive.build(), flush: true);
    stdout.writeln(target.path);
    return 0;
  }

  static Future<int> _clearLogs(CommandLineRequest request) async {
    final bool? confirmed = await _confirm(
      request,
      'Delete all existing DartFlutterDemo session logs? [y/N] ',
    );
    if (confirmed == null) {
      return 64;
    }
    if (!confirmed) {
      return 0;
    }
    final List<File> files = await listSystemInfoLogFiles();
    for (final File file in files) {
      await file.delete();
    }
    stdout.writeln('Deleted ${files.length} session log(s).');
    return 0;
  }

  static Future<bool?> _confirm(CommandLineRequest request, String prompt) async {
    if (request.assumeYes) return true;
    if (!stdin.hasTerminal) {
      stderr.writeln('This command requires --yes when standard input is not a terminal.');
      return null;
    }
    stdout.write(prompt);
    final String? answer = stdin.readLineSync()?.trim().toLowerCase();
    return answer == 'y' || answer == 'yes';
  }
}

/// Minimal ZIP writer for the CLI export. It uses stored entries, avoiding a
/// platform-specific zip executable and keeping exports portable on all three
/// desktop platforms.
class _ZipArchive {
  final BytesBuilder _body = BytesBuilder(copy: false);
  final List<_ZipEntry> _entries = <_ZipEntry>[];

  void addFile(String name, List<int> data, DateTime modified) {
    final List<int> nameBytes = utf8.encode(name);
    final Uint8List content = Uint8List.fromList(data);
    final int offset = _body.length;
    final _DosTimestamp timestamp = _DosTimestamp.from(modified);
    final int checksum = _crc32(content);
    _write32(_body, 0x04034b50);
    _write16(_body, 20);
    _write16(_body, 0);
    _write16(_body, 0);
    _write16(_body, timestamp.time);
    _write16(_body, timestamp.date);
    _write32(_body, checksum);
    _write32(_body, content.length);
    _write32(_body, content.length);
    _write16(_body, nameBytes.length);
    _write16(_body, 0);
    _body.add(nameBytes);
    _body.add(content);
    _entries.add(_ZipEntry(nameBytes, timestamp, checksum, content.length, offset));
  }

  Uint8List build() {
    final int centralOffset = _body.length;
    for (final _ZipEntry entry in _entries) {
      _write32(_body, 0x02014b50);
      _write16(_body, 20);
      _write16(_body, 20);
      _write16(_body, 0);
      _write16(_body, 0);
      _write16(_body, entry.timestamp.time);
      _write16(_body, entry.timestamp.date);
      _write32(_body, entry.checksum);
      _write32(_body, entry.length);
      _write32(_body, entry.length);
      _write16(_body, entry.name.length);
      _write16(_body, 0);
      _write16(_body, 0);
      _write16(_body, 0);
      _write16(_body, 0);
      _write32(_body, 0);
      _write32(_body, entry.offset);
      _body.add(entry.name);
    }
    final int centralLength = _body.length - centralOffset;
    _write32(_body, 0x06054b50);
    _write16(_body, 0);
    _write16(_body, 0);
    _write16(_body, _entries.length);
    _write16(_body, _entries.length);
    _write32(_body, centralLength);
    _write32(_body, centralOffset);
    _write16(_body, 0);
    return _body.toBytes();
  }
}

class _ZipEntry {
  const _ZipEntry(this.name, this.timestamp, this.checksum, this.length, this.offset);

  final List<int> name;
  final _DosTimestamp timestamp;
  final int checksum;
  final int length;
  final int offset;
}

class _DosTimestamp {
  const _DosTimestamp(this.time, this.date);

  factory _DosTimestamp.from(DateTime value) {
    final DateTime local = value.toLocal();
    final int year = local.year.clamp(1980, 2107).toInt();
    return _DosTimestamp(
      (local.hour << 11) | (local.minute << 5) | (local.second ~/ 2),
      ((year - 1980) << 9) | (local.month << 5) | local.day,
    );
  }

  final int time;
  final int date;
}

void _write16(BytesBuilder target, int value) {
  target.add(<int>[value & 0xff, (value >> 8) & 0xff]);
}

void _write32(BytesBuilder target, int value) {
  _write16(target, value & 0xffff);
  _write16(target, (value >> 16) & 0xffff);
}

int _crc32(List<int> data) {
  var result = 0xffffffff;
  for (final int byte in data) {
    result ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      result = (result & 1) == 0 ? result >> 1 : (result >> 1) ^ 0xedb88320;
    }
  }
  return (result ^ 0xffffffff) & 0xffffffff;
}
