import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/animated_page.dart';

enum _ControlScenario { normal, disabled, error, loading }

extension on _ControlScenario {
  String get label => switch (this) {
        _ControlScenario.normal => 'Normal',
        _ControlScenario.disabled => 'Disabled',
        _ControlScenario.error => 'Error',
        _ControlScenario.loading => 'Loading',
      };

  IconData get icon => switch (this) {
        _ControlScenario.normal => Icons.tune_rounded,
        _ControlScenario.disabled => Icons.block_rounded,
        _ControlScenario.error => Icons.error_outline_rounded,
        _ControlScenario.loading => Icons.hourglass_top_rounded,
      };
}

enum _TaskPhase { idle, running, paused, failed, succeeded, canceled }

extension on _TaskPhase {
  String get label => switch (this) {
        _TaskPhase.idle => 'Idle',
        _TaskPhase.running => 'Running',
        _TaskPhase.paused => 'Paused',
        _TaskPhase.failed => 'Failed',
        _TaskPhase.succeeded => 'Succeeded',
        _TaskPhase.canceled => 'Canceled',
      };

  IconData get icon => switch (this) {
        _TaskPhase.idle => Icons.schedule_rounded,
        _TaskPhase.running => Icons.play_arrow_rounded,
        _TaskPhase.paused => Icons.pause_rounded,
        _TaskPhase.failed => Icons.error_rounded,
        _TaskPhase.succeeded => Icons.check_circle_rounded,
        _TaskPhase.canceled => Icons.cancel_rounded,
      };
}

class Page4ControlsFeedback extends StatefulWidget {
  const Page4ControlsFeedback({super.key});

  @override
  State<Page4ControlsFeedback> createState() =>
      _Page4ControlsFeedbackState();
}

class _Page4ControlsFeedbackState extends State<Page4ControlsFeedback>
    with SingleTickerProviderStateMixin {
  _ControlScenario _scenario = _ControlScenario.normal;
  _TaskPhase _taskPhase = _TaskPhase.idle;

  int? _radioValue = 0;
  bool _checkA = true;
  bool _checkB = false;
  bool _checkC = true;
  bool? _mixedCheck;
  bool _switchA = true;
  bool _switchB = false;
  bool _switchC = true;
  bool _switchLong = true;

  bool _simulateFailure = false;
  bool _highContrastPreview = false;
  double _textScale = 1;
  String _focusedControl = 'None';
  final List<String> _feedbackHistory = <String>['Ready'];

  late final AnimationController _taskController;

  bool get _selectionEnabled =>
      _scenario == _ControlScenario.normal ||
      _scenario == _ControlScenario.error;

  double get _progress => _taskController.value;

  bool get _hasCheckedOption =>
      _checkA || _checkB || _checkC || _mixedCheck == true;

  @override
  void initState() {
    super.initState();
    _taskController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(_handleTaskTick)
      ..addStatusListener(_handleTaskStatus);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _handleTaskTick() {
    if (!mounted ||
        _taskPhase != _TaskPhase.running ||
        !_simulateFailure ||
        _taskController.value < 0.65) {
      return;
    }
    _taskController.stop();
    setState(() {
      _taskPhase = _TaskPhase.failed;
      _taskController.value = 0.65;
      _recordFeedback('Task failed at 65%');
    });
    _showTaskSnackBar('Task failed at 65%.', isError: true);
  }

  void _handleTaskStatus(AnimationStatus status) {
    if (!mounted ||
        status != AnimationStatus.completed ||
        _taskPhase != _TaskPhase.running) {
      return;
    }
    setState(() {
      _taskPhase = _TaskPhase.succeeded;
      _recordFeedback('Task completed');
    });
    _showTaskSnackBar('Processing completed.');
  }

  void _setScenario(Set<_ControlScenario> selection) {
    final next = selection.first;
    if (next == _scenario) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _scenario = next;
      if (next == _ControlScenario.error) {
        _radioValue = null;
        _checkA = false;
        _checkB = false;
        _checkC = false;
        _mixedCheck = null;
      }
      _recordFeedback('Scenario changed to ${next.label}');
    });
  }

  void _startTask() {
    _taskController
      ..stop()
      ..reset();
    setState(() {
      _taskPhase = _TaskPhase.running;
      _recordFeedback('Task started');
    });
    _taskController.forward();
  }

  void _pauseTask() {
    if (_taskPhase != _TaskPhase.running) return;
    _taskController.stop(canceled: false);
    setState(() {
      _taskPhase = _TaskPhase.paused;
      _recordFeedback('Task paused');
    });
  }

  void _resumeTask() {
    if (_taskPhase != _TaskPhase.paused) return;
    setState(() {
      _taskPhase = _TaskPhase.running;
      _recordFeedback('Task resumed');
    });
    _taskController.forward();
  }

  void _cancelTask() {
    if (_taskPhase != _TaskPhase.running &&
        _taskPhase != _TaskPhase.paused) {
      return;
    }
    _taskController.stop();
    setState(() {
      _taskPhase = _TaskPhase.canceled;
      _recordFeedback('Task canceled');
    });
    _showTaskSnackBar('Processing canceled.');
  }

  void _resetLab() {
    FocusManager.instance.primaryFocus?.unfocus();
    _taskController
      ..stop()
      ..reset();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..hideCurrentMaterialBanner();
    setState(() {
      _scenario = _ControlScenario.normal;
      _taskPhase = _TaskPhase.idle;
      _radioValue = 0;
      _checkA = true;
      _checkB = false;
      _checkC = true;
      _mixedCheck = null;
      _switchA = true;
      _switchB = false;
      _switchC = true;
      _switchLong = true;
      _simulateFailure = false;
      _highContrastPreview = false;
      _textScale = 1;
      _focusedControl = 'None';
      _feedbackHistory
        ..clear()
        ..add('Ready');
    });
  }

  void _recordFeedback(String message) {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    _feedbackHistory.insert(
      0,
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}  $message',
    );
    if (_feedbackHistory.length > 10) {
      _feedbackHistory.removeRange(10, _feedbackHistory.length);
    }
  }

  void _showTaskSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _setFocusedControl(String label, bool focused) {
    if (!mounted) return;
    final next = focused ? label : 'None';
    if (_focusedControl == next) return;
    setState(() => _focusedControl = next);
  }

  Widget _focusRegion(String label, Widget child) {
    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) => _setFocusedControl(label, focused),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final systemHighContrast = MediaQuery.highContrastOf(context);
    final mediaQuery = MediaQuery.of(context);
    final highContrastScheme = theme.brightness == Brightness.dark
        ? const ColorScheme.highContrastDark()
        : const ColorScheme.highContrastLight();
    final previewTheme = _highContrastPreview
        ? theme.copyWith(colorScheme: highContrastScheme)
        : theme;

    return AnimatedPageWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScenarioToolbar(theme),
                const SizedBox(height: 14),
                _buildStateInspector(theme, systemHighContrast),
                const SizedBox(height: 20),
                Theme(
                  data: previewTheme,
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(_textScale),
                    ),
                    child: Builder(
                      builder: (previewContext) {
                        final activeTheme = Theme.of(previewContext);
                        return FocusTraversalGroup(
                          policy: OrderedTraversalPolicy(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: FocusTraversalOrder(
                                        order: const NumericFocusOrder(1),
                                        child: _focusRegion(
                                          'Selection controls',
                                          _buildSelectionControls(
                                            activeTheme,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    Expanded(
                                      child: FocusTraversalOrder(
                                        order: const NumericFocusOrder(2),
                                        child: _focusRegion(
                                          'Accessibility preview',
                                          _buildAccessibilityPreview(
                                            activeTheme,
                                            systemHighContrast,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(1),
                                  child: _focusRegion(
                                    'Selection controls',
                                    _buildSelectionControls(activeTheme),
                                  ),
                                ),
                                const Divider(height: 36),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(2),
                                  child: _focusRegion(
                                    'Accessibility preview',
                                    _buildAccessibilityPreview(
                                      activeTheme,
                                      systemHighContrast,
                                    ),
                                  ),
                                ),
                              ],
                              const Divider(height: 44),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: _focusRegion(
                                  'Async task',
                                  _buildTaskSection(activeTheme),
                                ),
                              ),
                              const Divider(height: 44),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(4),
                                child: _focusRegion(
                                  'Feedback actions',
                                  _buildFeedbackSection(activeTheme),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScenarioToolbar(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.dashboard_customize_outlined,
            color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_ControlScenario>(
              key: const Key('page4-scenario-control'),
              segments: [
                for (final scenario in _ControlScenario.values)
                  ButtonSegment<_ControlScenario>(
                    value: scenario,
                    icon: Icon(scenario.icon),
                    label: Text(scenario.label),
                  ),
              ],
              selected: <_ControlScenario>{_scenario},
              onSelectionChanged: _setScenario,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const Key('page4-reset'),
          tooltip: 'Reset lab',
          onPressed: _resetLab,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    );
  }

  Widget _buildStateInspector(
    ThemeData theme,
    bool systemHighContrast,
  ) {
    return AnimatedBuilder(
      animation: _taskController,
      builder: (context, _) {
        final checks = <String>[
          if (_checkA) 'A',
          if (_checkB) 'B',
          if (_checkC) 'C',
          if (_mixedCheck == true) 'Mixed:on',
          if (_mixedCheck == null) 'Mixed:mixed',
        ];
        final switches = <String>[
          if (_switchA) 'A',
          if (_switchB) 'B',
          if (_switchC) 'C',
          if (_switchLong) 'Long',
        ];
        return Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.data_object_rounded,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live State Inspector',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy state as JSON',
                      onPressed: () => _copyState(systemHighContrast),
                      icon: const Icon(Icons.content_copy_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InspectorField('Scenario', 'enum', _scenario.label),
                    _InspectorField('Task', 'enum', _taskPhase.label),
                    _InspectorField(
                      'Radio',
                      'int?',
                      _radioValue == null
                          ? 'none'
                          : <String>['Alpha', 'Beta', 'Gamma'][_radioValue!],
                    ),
                    _InspectorField(
                      'Checks',
                      'List<bool?>',
                      checks.isEmpty ? 'none' : checks.join(', '),
                    ),
                    _InspectorField(
                      'Switches',
                      'Map<String, bool>',
                      switches.isEmpty ? 'all off' : switches.join(', '),
                    ),
                    _InspectorField(
                      'Progress',
                      'double',
                      '${(_progress * 100).round()}%',
                    ),
                    _InspectorField('Focus', 'String', _focusedControl),
                    _InspectorField(
                      'Contrast',
                      'String',
                      _highContrastPreview
                          ? 'preview'
                          : systemHighContrast
                              ? 'system'
                              : 'standard',
                    ),
                    _InspectorField(
                      'Text scale',
                      'double',
                      '${(_textScale * 100).round()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionControls(ThemeData theme) {
    final radioError =
        _scenario == _ControlScenario.error && _radioValue == null;
    final checkError =
        _scenario == _ControlScenario.error && !_hasCheckedOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          icon: Icons.checklist_rounded,
          title: 'Selection Controls',
          trailing: _scenario == _ControlScenario.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (_scenario == _ControlScenario.loading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 14),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Required choice',
            errorText: radioError ? 'Select Alpha, Beta, or Gamma.' : null,
            enabled: _selectionEnabled,
            border: const OutlineInputBorder(),
          ),
          isEmpty: _radioValue == null,
          child: RadioGroup<int>(
            groupValue: _radioValue,
            onChanged: _selectionEnabled
                ? (value) => setState(() => _radioValue = value)
                : (_) {},
            child: Column(
              children: [
                RadioListTile<int>(
                  key: const Key('page4-radio-alpha'),
                  title: const Text('Alpha'),
                  subtitle: const Text('Primary processing route'),
                  value: 0,
                  enabled: _selectionEnabled,
                  selected: _radioValue == 0,
                ),
                RadioListTile<int>(
                  key: const Key('page4-radio-beta'),
                  title: const Text('Beta'),
                  subtitle: const Text('Balanced processing route'),
                  value: 1,
                  enabled: _selectionEnabled,
                  selected: _radioValue == 1,
                ),
                RadioListTile<int>(
                  key: const Key('page4-radio-gamma'),
                  title: const Text('Gamma'),
                  subtitle: const Text('Experimental processing route'),
                  value: 2,
                  enabled: _selectionEnabled,
                  selected: _radioValue == 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Options',
            errorText: checkError ? 'Select at least one option.' : null,
            enabled: _selectionEnabled,
            border: const OutlineInputBorder(),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('Option A'),
                value: _checkA,
                onChanged: _selectionEnabled
                    ? (value) => setState(() => _checkA = value ?? false)
                    : null,
              ),
              CheckboxListTile(
                title: const Text('Option B'),
                value: _checkB,
                onChanged: _selectionEnabled
                    ? (value) => setState(() => _checkB = value ?? false)
                    : null,
              ),
              CheckboxListTile(
                title: const Text('Option C'),
                value: _checkC,
                onChanged: _selectionEnabled
                    ? (value) => setState(() => _checkC = value ?? false)
                    : null,
              ),
              CheckboxListTile(
                key: const Key('page4-checkbox-mixed'),
                title: const Text('Inherited option'),
                subtitle: const Text('Supports an indeterminate value'),
                tristate: true,
                value: _mixedCheck,
                onChanged: _selectionEnabled
                    ? (value) => setState(() => _mixedCheck = value)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Feature switches',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SwitchListTile(
          title: const Text('Enable feature A'),
          value: _switchA,
          onChanged: _selectionEnabled
              ? (value) => setState(() => _switchA = value)
              : null,
        ),
        SwitchListTile(
          title: const Text('Enable feature B'),
          value: _switchB,
          onChanged: _selectionEnabled
              ? (value) => setState(() => _switchB = value)
              : null,
        ),
        SwitchListTile(
          title: const Text('Enable feature C'),
          value: _switchC,
          onChanged: _selectionEnabled
              ? (value) => setState(() => _switchC = value)
              : null,
        ),
        SwitchListTile(
          title: const Text(
            'Keep background synchronization enabled when this label wraps '
            'onto multiple lines',
          ),
          value: _switchLong,
          onChanged: _selectionEnabled
              ? (value) => setState(() => _switchLong = value)
              : null,
        ),
      ],
    );
  }

  Widget _buildAccessibilityPreview(
    ThemeData theme,
    bool systemHighContrast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          icon: Icons.accessibility_new_rounded,
          title: 'Accessibility Preview',
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          key: const Key('page4-high-contrast'),
          title: const Text('High contrast preview'),
          subtitle: Text(
            systemHighContrast
                ? 'System high contrast is active'
                : 'System high contrast is inactive',
          ),
          value: _highContrastPreview,
          onChanged: (value) =>
              setState(() => _highContrastPreview = value),
        ),
        const SizedBox(height: 12),
        Text(
          'Text scale',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<double>(
            key: const Key('page4-text-scale'),
            segments: const [
              ButtonSegment<double>(value: 1, label: Text('100%')),
              ButtonSegment<double>(value: 1.5, label: Text('150%')),
              ButtonSegment<double>(value: 2, label: Text('200%')),
            ],
            selected: <double>{_textScale},
            onSelectionChanged: (selection) =>
                setState(() => _textScale = selection.first),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly activity summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Background synchronization completed successfully. Twelve '
                'recent projects are ready to review across your devices.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.contrast_rounded, size: 18),
                    label: Text(
                      _highContrastPreview ? 'Preview contrast' : 'App colors',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.keyboard_rounded, size: 18),
                    label: Text('Focus: $_focusedControl'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSection(ThemeData theme) {
    final allowFailureChange =
        _taskPhase != _TaskPhase.running && _taskPhase != _TaskPhase.paused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          icon: Icons.pending_actions_rounded,
          title: 'Async Task State Machine',
          trailing: Semantics(
            label: 'Task status',
            value: _taskPhase.label,
            liveRegion: true,
            excludeSemantics: true,
            child: Chip(
              avatar: Icon(
                _taskPhase.icon,
                size: 18,
                color: _taskColor(theme.colorScheme),
              ),
              label: Text(_taskPhase.label),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          key: const Key('page4-simulate-failure'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Simulate failure at 65%'),
          value: _simulateFailure,
          onChanged: allowFailureChange
              ? (value) => setState(() => _simulateFailure = value)
              : null,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._taskActions(),
            if (_taskPhase == _TaskPhase.running) ...[
              const SizedBox(
                key: Key('page4-indeterminate-progress'),
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const Text('Processing...'),
            ],
          ],
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _taskController,
          builder: (context, _) {
            final percent = (_progress * 100).round();
            return Semantics(
              label: 'Task progress',
              value: '$percent percent',
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      key: const Key('page4-circular-progress'),
                      value: _progress,
                      strokeWidth: 5,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(_taskPhase.label)),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          key: const Key('page4-linear-progress'),
                          value: _progress,
                          minHeight: 9,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_taskPhase == _TaskPhase.failed) ...[
          const SizedBox(height: 12),
          Text(
            'The deterministic failure was triggered at 65%.',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _taskActions() {
    return switch (_taskPhase) {
      _TaskPhase.idle => [
          FilledButton.icon(
            key: const Key('page4-task-start'),
            onPressed: _startTask,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start'),
          ),
        ],
      _TaskPhase.running => [
          FilledButton.tonalIcon(
            key: const Key('page4-task-pause'),
            onPressed: _pauseTask,
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
          ),
          OutlinedButton.icon(
            key: const Key('page4-task-cancel'),
            onPressed: _cancelTask,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
          ),
        ],
      _TaskPhase.paused => [
          FilledButton.icon(
            key: const Key('page4-task-resume'),
            onPressed: _resumeTask,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Resume'),
          ),
          OutlinedButton.icon(
            key: const Key('page4-task-cancel'),
            onPressed: _cancelTask,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
          ),
        ],
      _TaskPhase.failed => [
          FilledButton.icon(
            key: const Key('page4-task-retry'),
            onPressed: _startTask,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      _TaskPhase.succeeded || _TaskPhase.canceled => [
          FilledButton.icon(
            key: const Key('page4-task-restart'),
            onPressed: _startTask,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Run again'),
          ),
        ],
    };
  }

  Widget _buildFeedbackSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          theme,
          icon: Icons.notifications_active_outlined,
          title: 'Feedback Actions',
          trailing: IconButton(
            tooltip: 'Clear feedback',
            onPressed: _clearFeedback,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              key: const Key('page4-standard-snackbar'),
              onPressed: _showStandardSnackBar,
              icon: const Icon(Icons.space_bar_rounded),
              label: const Text('SnackBar'),
            ),
            FilledButton.tonalIcon(
              key: const Key('page4-floating-snackbar'),
              onPressed: _showFloatingSnackBar,
              icon: const Icon(Icons.vertical_align_center_rounded),
              label: const Text('Floating SnackBar'),
            ),
            OutlinedButton.icon(
              key: const Key('page4-info-dialog'),
              onPressed: _showInfoDialog,
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Info dialog'),
            ),
            FilledButton.tonalIcon(
              key: const Key('page4-material-banner'),
              onPressed: _showDemoBanner,
              icon: const Icon(Icons.view_agenda_outlined),
              label: const Text('Material banner'),
            ),
            OutlinedButton.icon(
              key: const Key('page4-bottom-sheet'),
              onPressed: _showDemoBottomSheet,
              icon: const Icon(Icons.call_to_action_outlined),
              label: const Text('Bottom sheet'),
            ),
            OutlinedButton.icon(
              key: const Key('page4-confirm-dialog'),
              onPressed: _showConfirmDialog,
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text('Confirmation'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Feedback History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final entry in _feedbackHistory)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    entry,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Color _taskColor(ColorScheme colors) => switch (_taskPhase) {
        _TaskPhase.failed => colors.error,
        _TaskPhase.succeeded => colors.tertiary,
        _TaskPhase.running => colors.primary,
        _TaskPhase.paused => colors.secondary,
        _TaskPhase.canceled => colors.outline,
        _TaskPhase.idle => colors.onSurfaceVariant,
      };

  Map<String, Object?> _stateMap(bool systemHighContrast) => <String, Object?>{
        'scenario': _scenario.label,
        'radio': _radioValue == null
            ? null
            : <String>['Alpha', 'Beta', 'Gamma'][_radioValue!],
        'checkboxes': <String, Object?>{
          'optionA': _checkA,
          'optionB': _checkB,
          'optionC': _checkC,
          'inherited': _mixedCheck,
        },
        'switches': <String, bool>{
          'featureA': _switchA,
          'featureB': _switchB,
          'featureC': _switchC,
          'backgroundSync': _switchLong,
        },
        'task': <String, Object?>{
          'phase': _taskPhase.label,
          'progress': double.parse(_progress.toStringAsFixed(3)),
          'simulateFailure': _simulateFailure,
        },
        'accessibility': <String, Object?>{
          'focusedRegion': _focusedControl,
          'systemHighContrast': systemHighContrast,
          'highContrastPreview': _highContrastPreview,
          'textScale': _textScale,
        },
      };

  Future<void> _copyState(bool systemHighContrast) async {
    final json = const JsonEncoder.withIndent('  ').convert(
      _stateMap(systemHighContrast),
    );
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    setState(() => _recordFeedback('State JSON copied'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('State copied as JSON.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStandardSnackBar() {
    setState(() => _recordFeedback('SnackBar shown'));
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('This is a standard SnackBar message.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showFloatingSnackBar() {
    setState(() => _recordFeedback('Floating SnackBar shown'));
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Action completed successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showInfoDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information'),
        content: const Text('The dialog completed without changing state.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _recordFeedback('Info dialog closed'));
  }

  void _showDemoBanner() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    setState(() => _recordFeedback('Material banner shown'));
    messenger.showMaterialBanner(
      MaterialBanner(
        content: const Text('A persistent message is available for review.'),
        leading: const Icon(Icons.info_outline_rounded),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              if (mounted) {
                setState(() => _recordFeedback('Material banner dismissed'));
              }
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDemoBottomSheet() async {
    setState(() => _recordFeedback('Bottom sheet opened'));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review current selection',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('The selected values are ready to be applied.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _recordFeedback('Bottom sheet closed'));
  }

  Future<void> _showConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm action'),
        content: const Text('Apply the pending control state?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _recordFeedback(
          confirmed == true ? 'Action confirmed' : 'Action canceled',
        ));
  }

  void _clearFeedback() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..hideCurrentMaterialBanner();
    setState(() {
      _feedbackHistory
        ..clear()
        ..add('Feedback cleared');
    });
  }
}

class _InspectorField extends StatelessWidget {
  const _InspectorField(this.label, this.type, this.value);

  final String label;
  final String type;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 138, maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        type,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
