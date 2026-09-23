import 'package:flutter/services.dart';

import 'models.dart';

/// Platform contract of the Windows desktop integration.
abstract class WindowsDesktopIntegrationPlatform {
  /// Allows subclasses, including test doubles, to use `const`.
  const WindowsDesktopIntegrationPlatform();

  /// The active implementation, replaceable in tests.
  static WindowsDesktopIntegrationPlatform instance =
      const MethodChannelWindowsDesktopIntegration();

  /// Claims a single instance slot, returning false for a secondary launch.
  Future<bool> acquireSingleInstance();

  /// Replaces the jump list entries of the application.
  Future<void> setJumpList(List<TaskbarEntry> entries);

  /// Replaces the thumbnail toolbar buttons.
  Future<void> setThumbnailToolbar(
    List<TaskbarToolbarButton> buttons, {
    String? activeId,
  });

  /// Shows the shell notification that reports an applied desktop request.
  ///
  /// Returns false when the platform has no notification implementation or
  /// refused to show one.
  Future<bool> showNotification({required String title, required String body});

  /// Stream of taskbar events.
  Stream<TaskbarEvent> get events;
}

/// Default implementation backed by a method channel and an event channel.
class MethodChannelWindowsDesktopIntegration
    extends WindowsDesktopIntegrationPlatform {
  /// Creates the default platform implementation.
  const MethodChannelWindowsDesktopIntegration();

  static const MethodChannel _methods =
      MethodChannel('windows_desktop_integration_vincentzyu/methods');
  static const EventChannel _events =
      EventChannel('windows_desktop_integration_vincentzyu/events');

  @override
  Future<bool> acquireSingleInstance() async {
    try {
      return await _methods.invokeMethod<bool>('acquireSingleInstance') ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  @override
  Future<void> setJumpList(List<TaskbarEntry> entries) async {
    try {
      await _methods.invokeMethod<void>('setJumpList', <String, Object?>{
        'entries':
            entries.map((entry) => entry.toMap()).toList(growable: false),
      });
    } on MissingPluginException {
      // No Windows desktop integration on this platform.
    } on PlatformException {
      // A rejected jump list must never break the application.
    }
  }

  @override
  Future<void> setThumbnailToolbar(
    List<TaskbarToolbarButton> buttons, {
    String? activeId,
  }) async {
    try {
      await _methods
          .invokeMethod<void>('setThumbnailToolbar', <String, Object?>{
        'activeId': activeId,
        'buttons':
            buttons.map((button) => button.toMap()).toList(growable: false),
      });
    } on MissingPluginException {
      // No Windows desktop integration on this platform.
    } on PlatformException {
      // A rejected toolbar must never break the application.
    }
  }

  @override
  Stream<TaskbarEvent> get events => _events
          .receiveBroadcastStream()
          .map(TaskbarEvent.fromMap)
          .where((event) => event != null)
          .cast<TaskbarEvent>()
          .handleError((Object _) {
        // Platforms without the event channel simply produce no events.
      });

  @override
  Future<bool> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      final bool? shown = await _methods
          .invokeMethod<bool>('showNotification', <String, Object?>{
        'title': title,
        'body': body,
      });
      return shown ?? false;
    } on MissingPluginException {
      // No Windows desktop integration on this platform.
      return false;
    } on PlatformException {
      // A refused notification must never break the application.
      return false;
    }
  }
}
