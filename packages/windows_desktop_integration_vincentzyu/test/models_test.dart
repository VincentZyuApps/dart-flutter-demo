import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:windows_desktop_integration_vincentzyu/windows_desktop_integration_vincentzyu.dart';

void main() {
  group('TaskbarEntry', () {
    test('serialises every field for the native plugin', () {
      const TaskbarEntry entry = TaskbarEntry(
        id: 'grid',
        label: 'Adaptive Grid',
        arguments: '--tab=grid',
      );

      expect(entry.toMap(), <String, Object?>{
        'id': 'grid',
        'label': 'Adaptive Grid',
        'arguments': '--tab=grid',
      });
    });

    test('carries the icon file of an entry', () {
      const TaskbarEntry entry = TaskbarEntry(
        id: 'guide',
        label: 'Guide',
        arguments: '--action=guide',
        iconPath: '/icons/guide-dark-01234567.ico',
      );

      expect(entry.toMap(), <String, Object?>{
        'id': 'guide',
        'label': 'Guide',
        'arguments': '--action=guide',
        'iconPath': '/icons/guide-dark-01234567.ico',
      });
    });
  });

  group('TaskbarToolbarButton', () {
    test('flattens the icon into the wire format', () {
      final TaskbarIcon icon = TaskbarIcon(
        width: 1,
        height: 1,
        rgba: Uint8List.fromList(<int>[1, 2, 3, 4]),
      );
      final TaskbarToolbarButton button = TaskbarToolbarButton(
        id: 'about',
        label: 'About',
        arguments: '--action=about',
        icon: icon,
      );

      expect(button.toMap(), <String, Object?>{
        'id': 'about',
        'label': 'About',
        'arguments': '--action=about',
        'enabled': true,
        'width': 1,
        'height': 1,
        'icon': icon.rgba,
      });
    });

    test('can mark the active page as disabled', () {
      final TaskbarToolbarButton button = TaskbarToolbarButton(
        id: 'system',
        label: 'System Info',
        arguments: '--tab=system',
        icon: TaskbarIcon(
          width: 1,
          height: 1,
          rgba: Uint8List(4),
        ),
        enabled: false,
      );

      expect(button.toMap()['enabled'], isFalse);
    });
  });

  group('TaskbarEvent', () {
    test('parses a thumbnail toolbar click', () {
      final TaskbarEvent? event = TaskbarEvent.fromMap(<Object?, Object?>{
        'type': 'command',
        'id': 'controls',
      });

      expect(event?.type, TaskbarEventType.command);
      expect(event?.commandId, 'controls');
      expect(event?.arguments, isEmpty);
    });

    test('parses a forwarded command line', () {
      final TaskbarEvent? event = TaskbarEvent.fromMap(<Object?, Object?>{
        'type': 'launch',
        'arguments': <Object?>['--tab=grid', 7],
      });

      expect(event?.type, TaskbarEventType.launch);
      expect(event?.commandId, isNull);
      expect(event?.arguments, <String>['--tab=grid']);
    });

    test('accepts a forwarded launch without arguments', () {
      final TaskbarEvent? event = TaskbarEvent.fromMap(<Object?, Object?>{
        'type': 'launch',
      });

      expect(event?.type, TaskbarEventType.launch);
      expect(event?.arguments, isEmpty);
    });

    test('rejects unknown payloads', () {
      expect(TaskbarEvent.fromMap(null), isNull);
      expect(TaskbarEvent.fromMap('command'), isNull);
      expect(TaskbarEvent.fromMap(<Object?, Object?>{'type': 'other'}), isNull);
      expect(
        TaskbarEvent.fromMap(<Object?, Object?>{'type': 'command', 'id': 7}),
        isNull,
      );
    });
  });
}
