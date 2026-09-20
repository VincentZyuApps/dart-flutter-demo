import 'package:dart_flutter_demo/services/taskbar_integration_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Removes every request that another test left in the queue.
void drainPendingRequests() {
  while (takePendingDesktopRequest() != null) {
    // Keep draining until the desktop shell queue is empty.
  }
}

void main() {
  group('desktop shortcut table', () {
    test('exposes five pages plus the two drawer destinations', () {
      expect(desktopShortcuts.length, 7);
      expect(
        desktopShortcuts
            .where(
              (DesktopShortcut shortcut) =>
                  shortcut.kind == DesktopShortcutKind.page,
            )
            .length,
        desktopPageCount,
      );
    });

    test('maps every page to its own bottom navigation index', () {
      for (int index = 0; index < desktopPageCount; index++) {
        final DesktopShortcut shortcut = desktopShortcuts[index];
        expect(shortcut.kind, DesktopShortcutKind.page);
        expect(shortcut.pageIndex, index);
        expect(shortcut.label, desktopPageLabels[index]);
        expect(shortcut.arguments, '--tab=${shortcut.id}');
      }
    });

    test('keeps the drawer destinations after the pages', () {
      final DesktopShortcut about = desktopShortcuts[desktopPageCount];
      final DesktopShortcut guide = desktopShortcuts[desktopPageCount + 1];
      expect(about.kind, DesktopShortcutKind.about);
      expect(about.arguments, '--action=about');
      expect(guide.kind, DesktopShortcutKind.guide);
      expect(guide.arguments, '--action=guide');
    });

    test('keeps identifiers unique', () {
      final Set<String> ids =
          desktopShortcuts.map((DesktopShortcut shortcut) => shortcut.id).toSet();
      expect(ids.length, desktopShortcuts.length);
    });
  });

  group('matchShortcut', () {
    test('matches a plain page argument', () {
      expect(
        TaskbarIntegrationService.matchShortcut(<String>['--tab=grid'])?.id,
        'grid',
      );
    });

    test('matches inside a forwarded command line', () {
      expect(
        TaskbarIntegrationService.matchShortcut(<String>[
          'dart_flutter_demo --action=guide',
        ])?.id,
        'guide',
      );
    });

    test('ignores unrelated arguments', () {
      expect(TaskbarIntegrationService.matchShortcut(const <String>[]), isNull);
      expect(
        TaskbarIntegrationService.matchShortcut(<String>['--verbose']),
        isNull,
      );
      expect(
        TaskbarIntegrationService.matchShortcut(<String>['--tab=unknown']),
        isNull,
      );
    });
  });

  group('shortcutById', () {
    test('resolves thumbnail toolbar identifiers', () {
      expect(TaskbarIntegrationService.shortcutById('controls')?.pageIndex, 4);
      expect(TaskbarIntegrationService.shortcutById('about')?.kind,
          DesktopShortcutKind.about);
      expect(TaskbarIntegrationService.shortcutById(null), isNull);
      expect(TaskbarIntegrationService.shortcutById('missing'), isNull);
    });
  });

  group('pending requests', () {
    tearDown(() {
      drainPendingRequests();
    });

    test('drains forwarded launches in order', () {
      drainPendingRequests();
      TaskbarIntegrationService.handleLaunchArguments(<String>['--tab=grid']);
      TaskbarIntegrationService.handleLaunchArguments(<String>['--action=about']);
      expect(takePendingDesktopRequest()?.id, 'grid');
      expect(takePendingDesktopRequest()?.id, 'about');
      expect(takePendingDesktopRequest(), isNull);
    });

    test('queues nothing for an unknown command line', () {
      drainPendingRequests();
      TaskbarIntegrationService.handleLaunchArguments(<String>['--tab=unknown']);
      expect(takePendingDesktopRequest(), isNull);
    });

    test('notifies listeners for every queued request', () {
      drainPendingRequests();
      final int before = desktopRequestNotifier.value;
      TaskbarIntegrationService.handleLaunchArguments(<String>['--tab=type']);
      expect(desktopRequestNotifier.value, before + 1);
    });
  });
}
