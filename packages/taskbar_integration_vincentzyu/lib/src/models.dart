import 'dart:typed_data';

/// One entry of the Windows jump list.
class TaskbarEntry {
  const TaskbarEntry({
    required this.id,
    required this.label,
    required this.arguments,
    this.separatorBefore = false,
  });

  /// Stable identifier, also used by [TaskbarEvent.commandId].
  final String id;

  /// Title rendered in the jump list.
  final String label;

  /// Command line arguments used when the entry starts the executable.
  final String arguments;

  /// Inserts a jump list separator before this entry.
  final bool separatorBefore;

  /// Wire format consumed by the native plugin.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'arguments': arguments,
      'separatorBefore': separatorBefore,
    };
  }
}

/// Premultiplied RGBA pixels of a toolbar button glyph.
class TaskbarIcon {
  const TaskbarIcon({
    required this.width,
    required this.height,
    required this.rgba,
  });

  /// Bitmap width in pixels.
  final int width;

  /// Bitmap height in pixels.
  final int height;

  /// Premultiplied RGBA bytes, `width * height * 4` long.
  final Uint8List rgba;
}

/// One button of the taskbar thumbnail toolbar.
class TaskbarToolbarButton {
  const TaskbarToolbarButton({
    required this.id,
    required this.label,
    required this.arguments,
    required this.icon,
    this.enabled = true,
  });

  /// Stable identifier reported back through [TaskbarEvent.commandId].
  final String id;

  /// Tooltip shown while hovering the button.
  final String label;

  /// Command line arguments equivalent of this button.
  final String arguments;

  /// Renderable glyph.
  final TaskbarIcon icon;

  /// Whether the button accepts clicks. The active page uses `false` to look
  /// pressed.
  final bool enabled;

  /// Wire format consumed by the native plugin.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'arguments': arguments,
      'enabled': enabled,
      'width': icon.width,
      'height': icon.height,
      'icon': icon.rgba,
    };
  }
}

/// Kind of message coming from the taskbar.
enum TaskbarEventType {
  /// A thumbnail toolbar button was clicked.
  command,

  /// Another process forwarded its command line to this instance.
  launch,
}

/// Message emitted by the taskbar integration.
class TaskbarEvent {
  /// A thumbnail toolbar button click.
  const TaskbarEvent.command(String clickedId)
      : type = TaskbarEventType.command,
        commandId = clickedId,
        arguments = const <String>[];

  /// A forwarded command line of a later launch.
  const TaskbarEvent.launch(List<String> forwarded)
      : type = TaskbarEventType.launch,
        commandId = null,
        arguments = forwarded;

  /// Message kind.
  final TaskbarEventType type;

  /// Clicked button identifier, set for [TaskbarEventType.command].
  final String? commandId;

  /// Forwarded arguments, set for [TaskbarEventType.launch].
  final List<String> arguments;

  /// Parses the native wire format. Returns null for unknown payloads.
  static TaskbarEvent? fromMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final Object? type = value['type'];
    if (type == 'command') {
      final Object? id = value['id'];
      return id is String ? TaskbarEvent.command(id) : null;
    }
    if (type == 'launch') {
      final Object? arguments = value['arguments'];
      if (arguments is List) {
        return TaskbarEvent.launch(
          arguments.whereType<String>().toList(growable: false),
        );
      }
      return TaskbarEvent.launch(const <String>[]);
    }
    return null;
  }
}
