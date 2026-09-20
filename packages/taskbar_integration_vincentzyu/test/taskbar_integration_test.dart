import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskbar_integration_vincentzyu/taskbar_integration_vincentzyu.dart';

class _RecordingTaskbarPlatform extends TaskbarIntegrationPlatform {
  _RecordingTaskbarPlatform();

  bool primary = true;
  final List<String> calls = <String>[];
  final StreamController<TaskbarEvent> _events =
      StreamController<TaskbarEvent>.broadcast();

  List<TaskbarEntry>? jumpList;
  List<TaskbarToolbarButton>? toolbar;
  String? toolbarActiveId;

  @override
  Future<bool> acquireSingleInstance() async {
    calls.add('acquireSingleInstance');
    return primary;
  }

  @override
  Future<void> setJumpList(List<TaskbarEntry> entries) async {
    calls.add('setJumpList');
    jumpList = entries;
  }

  @override
  Future<void> setThumbnailToolbar(
    List<TaskbarToolbarButton> buttons, {
    String? activeId,
  }) async {
    calls.add('setThumbnailToolbar');
    toolbar = buttons;
    toolbarActiveId = activeId;
  }

  @override
  Stream<TaskbarEvent> get events => _events.stream;

  void emit(TaskbarEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}

void main() {
  late _RecordingTaskbarPlatform platform;
  late TaskbarIntegrationPlatform original;

  setUp(() {
    original = TaskbarIntegrationPlatform.instance;
    platform = _RecordingTaskbarPlatform();
    TaskbarIntegrationPlatform.instance = platform;
  });

  tearDown(() async {
    TaskbarIntegrationPlatform.instance = original;
    await platform.close();
  });

  test('reports the single instance result of the platform', () async {
    expect(await TaskbarIntegration.acquireSingleInstance(), isTrue);
    platform.primary = false;
    expect(await TaskbarIntegration.acquireSingleInstance(), isFalse);
    expect(platform.calls, <String>['acquireSingleInstance', 'acquireSingleInstance']);
  });

  test('forwards jump list entries in order', () async {
    const List<TaskbarEntry> entries = <TaskbarEntry>[
      TaskbarEntry(id: 'system', label: 'System Info', arguments: '--tab=system'),
      TaskbarEntry(
        id: 'about',
        label: 'About',
        arguments: '--action=about',
        separatorBefore: true,
      ),
    ];

    await TaskbarIntegration.setJumpList(entries);

    expect(platform.jumpList, same(entries));
  });

  test('forwards toolbar buttons and the active page hint', () async {
    final List<TaskbarToolbarButton> buttons = <TaskbarToolbarButton>[
      TaskbarToolbarButton(
        id: 'grid',
        label: 'Adaptive Grid',
        arguments: '--tab=grid',
        icon: TaskbarIcon(width: 1, height: 1, rgba: Uint8List(4)),
        enabled: false,
      ),
    ];

    await TaskbarIntegration.setThumbnailToolbar(buttons, activeId: 'grid');

    expect(platform.toolbar, same(buttons));
    expect(platform.toolbarActiveId, 'grid');
  });

  test('exposes platform events', () async {
    final List<TaskbarEvent> received = <TaskbarEvent>[];
    final StreamSubscription<TaskbarEvent> subscription =
        TaskbarIntegration.events.listen(received.add);
    platform.emit(const TaskbarEvent.command('type'));
    await pumpEventQueue();
    await subscription.cancel();

    expect(received, hasLength(1));
    expect(received.single.type, TaskbarEventType.command);
    expect(received.single.commandId, 'type');
  });
}
