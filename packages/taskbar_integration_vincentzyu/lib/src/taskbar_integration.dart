import 'models.dart';
import 'taskbar_integration_platform.dart';

/// Entry point of the Windows taskbar integration.
class TaskbarIntegration {
  const TaskbarIntegration._();

  /// Claims a single instance slot.
  ///
  /// Returns false when another instance already owns the slot and received the
  /// command line of this launch; the caller should exit immediately.
  static Future<bool> acquireSingleInstance() {
    return TaskbarIntegrationPlatform.instance.acquireSingleInstance();
  }

  /// Replaces the jump list entries shown when the taskbar button is right
  /// clicked.
  static Future<void> setJumpList(List<TaskbarEntry> entries) {
    return TaskbarIntegrationPlatform.instance.setJumpList(entries);
  }

  /// Replaces the buttons shown in the taskbar hover preview.
  static Future<void> setThumbnailToolbar(
    List<TaskbarToolbarButton> buttons, {
    String? activeId,
  }) {
    return TaskbarIntegrationPlatform.instance
        .setThumbnailToolbar(buttons, activeId: activeId);
  }

  /// Shows the shell notification that reports an applied desktop request.
  static Future<bool> showNotification({
    required String title,
    required String body,
  }) {
    return TaskbarIntegrationPlatform.instance.showNotification(
      title: title,
      body: body,
    );
  }

  /// Taskbar events of this instance.
  static Stream<TaskbarEvent> get events =>
      TaskbarIntegrationPlatform.instance.events;
}
