import 'package:dart_flutter_demo/services/desktop_integration_service.dart';
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
      final Set<String> ids = desktopShortcuts
          .map((DesktopShortcut shortcut) => shortcut.id)
          .toSet();
      expect(ids.length, desktopShortcuts.length);
    });
  });

  group('matchShortcut', () {
    test('matches a plain page argument', () {
      expect(
        DesktopIntegrationService.matchShortcut(<String>['--tab=grid'])?.id,
        'grid',
      );
    });

    test('matches inside a forwarded command line', () {
      expect(
        DesktopIntegrationService.matchShortcut(<String>[
          'dart_flutter_demo --action=guide',
        ])?.id,
        'guide',
      );
    });

    test('ignores unrelated arguments', () {
      expect(DesktopIntegrationService.matchShortcut(const <String>[]), isNull);
      expect(
        DesktopIntegrationService.matchShortcut(<String>['--verbose']),
        isNull,
      );
      expect(
        DesktopIntegrationService.matchShortcut(<String>['--tab=unknown']),
        isNull,
      );
    });
  });

  group('shortcutById', () {
    test('resolves thumbnail toolbar identifiers', () {
      expect(DesktopIntegrationService.shortcutById('controls')?.pageIndex, 4);
      expect(DesktopIntegrationService.shortcutById('about')?.kind,
          DesktopShortcutKind.about);
      expect(DesktopIntegrationService.shortcutById(null), isNull);
      expect(DesktopIntegrationService.shortcutById('missing'), isNull);
    });
  });

  group('KdeWaylandFocusPolicy', () {
    test('defaults to safe and accepts only the explicit policies', () {
      expect(
        KdeWaylandFocusPolicy.fromArguments(const <String>[]),
        KdeWaylandFocusPolicy.safe,
      );
      expect(
        KdeWaylandFocusPolicy.fromArguments(
          const <String>['--kde-wayland-focus=mpris'],
        ),
        KdeWaylandFocusPolicy.mpris,
      );
      expect(
        KdeWaylandFocusPolicy.fromArguments(
          const <String>['--kde-wayland-focus=all'],
        ),
        KdeWaylandFocusPolicy.all,
      );
    });
  });

  group('pending requests', () {
    tearDown(() {
      drainPendingRequests();
    });

    test('drains forwarded launches in order', () {
      drainPendingRequests();
      DesktopIntegrationService.handleLaunchArguments(<String>['--tab=grid']);
      DesktopIntegrationService.handleLaunchArguments(
          <String>['--action=about']);
      expect(takePendingDesktopRequest()?.id, 'grid');
      expect(takePendingDesktopRequest()?.id, 'about');
      expect(takePendingDesktopRequest(), isNull);
    });

    test('queues nothing for an unknown command line', () {
      drainPendingRequests();
      DesktopIntegrationService.handleLaunchArguments(
          <String>['--tab=unknown']);
      expect(takePendingDesktopRequest(), isNull);
    });

    test('notifies listeners for every queued request', () {
      drainPendingRequests();
      final int before = desktopRequestNotifier.value;
      DesktopIntegrationService.handleLaunchArguments(<String>['--tab=type']);
      expect(desktopRequestNotifier.value, before + 1);
    });
  });
}
