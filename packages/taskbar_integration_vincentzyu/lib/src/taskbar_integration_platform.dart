import 'package:flutter/services.dart';

import 'models.dart';

/// Platform contract of the taskbar integration.
abstract class TaskbarIntegrationPlatform {
  /// Allows subclasses, including test doubles, to use `const`.
  const TaskbarIntegrationPlatform();

  /// The active implementation, replaceable in tests.
  static TaskbarIntegrationPlatform instance =
      const MethodChannelTaskbarIntegration();

  /// Claims a single instance slot, returning false for a secondary launch.
  Future<bool> acquireSingleInstance();

  /// Replaces the jump list entries of the application.
  Future<void> setJumpList(List<TaskbarEntry> entries);

  /// Replaces the thumbnail toolbar buttons.
  Future<void> setThumbnailToolbar(
    List<TaskbarToolbarButton> buttons, {
    String? activeId,
  });

  /// Stream of taskbar events.
  Stream<TaskbarEvent> get events;
}

/// Default implementation backed by a method channel and an event channel.
class MethodChannelTaskbarIntegration extends TaskbarIntegrationPlatform {
  /// Creates the default platform implementation.
  const MethodChannelTaskbarIntegration();

  static const MethodChannel _methods =
      MethodChannel('taskbar_integration_vincentzyu/methods');
  static const EventChannel _events =
      EventChannel('taskbar_integration_vincentzyu/events');

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
        'entries': entries.map((entry) => entry.toMap()).toList(growable: false),
      });
    } on MissingPluginException {
      // No taskbar integration on this platform.
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
      await _methods.invokeMethod<void>('setThumbnailToolbar', <String, Object?>{
        'activeId': activeId,
        'buttons':
            buttons.map((button) => button.toMap()).toList(growable: false),
      });
    } on MissingPluginException {
      // No taskbar integration on this platform.
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
}
