import 'package:dart_flutter_demo/services/command_line_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommandLineRequest', () {
    test('keeps a normal desktop shortcut launch in GUI mode', () {
      final CommandLineRequest request =
          CommandLineRequest.parse(<String>['--tab=controls']);

      expect(request.mode, CommandLineMode.gui);
      expect(request.hasError, isFalse);

      expect(
        CommandLineRequest.parse(<String>['--action=about']).hasError,
        isFalse,
      );
    });

    test('accepts the safe maintenance commands without a GUI', () {
      expect(
        CommandLineRequest.parse(<String>['--help']).mode,
        CommandLineMode.help,
      );
      expect(
        CommandLineRequest.parse(<String>['-V']).mode,
        CommandLineMode.version,
      );
      expect(
        CommandLineRequest.parse(<String>['--system-info=json']).mode,
        CommandLineMode.systemInfoJson,
      );
      expect(
        CommandLineRequest.parse(<String>['--log-dir']).mode,
        CommandLineMode.logDirectory,
      );
      expect(
        CommandLineRequest.parse(<String>['--list-logs']).mode,
        CommandLineMode.listLogs,
      );
    });

    test('keeps help text and version options discoverable', () {
      expect(
        CommandLineService.usage,
        contains('DartFlutterDemo command line'),
      );
      expect(CommandLineService.usage, contains('-V, --version'));
      expect(CommandLineService.usage, contains('--system-info[=json]'));
    });

    test('requires explicit paths and confirmation for destructive commands', () {
      final CommandLineRequest export = CommandLineRequest.parse(<String>[
        '--export-logs',
        'support.zip',
        '--yes',
      ]);
      expect(export.mode, CommandLineMode.exportLogs);
      expect(export.exportPath, 'support.zip');
      expect(export.assumeYes, isTrue);
      expect(export.hasError, isFalse);

      expect(
        CommandLineRequest.parse(<String>['--export-logs']).hasError,
        isTrue,
      );
      expect(
        CommandLineRequest.parse(<String>['--clear-logs', '--yes']).hasError,
        isFalse,
      );
    });

    test('only permits privacy opt-in with system information', () {
      final CommandLineRequest accepted = CommandLineRequest.parse(<String>[
        '--system-info',
        '--include-sensitive',
      ]);
      expect(accepted.includeSensitive, isTrue);
      expect(accepted.hasError, isFalse);

      expect(
        CommandLineRequest.parse(<String>['--version', '--include-sensitive'])
            .hasError,
        isTrue,
      );
    });

    test('validates KDE Wayland focus policies without making them commands', () {
      expect(
        CommandLineRequest.parse(
          <String>['--kde-wayland-focus=mpris'],
        ).mode,
        CommandLineMode.gui,
      );
      expect(
        CommandLineRequest.parse(
          <String>['--version', '--kde-wayland-focus=mpris'],
        ).hasError,
        isTrue,
      );
      expect(
        CommandLineRequest.parse(
          <String>['--kde-wayland-focus=unsafe'],
        ).hasError,
        isTrue,
      );
    });
  });
}
