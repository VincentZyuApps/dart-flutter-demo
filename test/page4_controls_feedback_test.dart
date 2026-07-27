import 'package:dart_flutter_demo/pages/page4_controls_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLab(
    WidgetTester tester, {
    Size size = const Size(1200, 1000),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Page4ControlsFeedback()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('scenario modes expose disabled and validation states', (
    tester,
  ) async {
    await pumpLab(tester);

    await tester.tap(find.text('Disabled'));
    await tester.pump();
    final disabledRadio = tester.widget<RadioListTile<int>>(
      find.byKey(const Key('page4-radio-alpha')),
    );
    expect(disabledRadio.enabled, isFalse);

    await tester.tap(find.text('Error'));
    await tester.pump();
    expect(find.text('Select Alpha, Beta, or Gamma.'), findsOneWidget);
    expect(find.text('Select at least one option.'), findsOneWidget);
  });

  testWidgets('retains the original control and feedback surface', (
    tester,
  ) async {
    await pumpLab(tester);

    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);
    expect(find.text('Option C'), findsOneWidget);
    expect(find.text('Enable feature A'), findsOneWidget);
    expect(find.text('Enable feature B'), findsOneWidget);
    expect(find.text('Enable feature C'), findsOneWidget);
    expect(find.byKey(const Key('page4-linear-progress')), findsOneWidget);
    expect(find.byKey(const Key('page4-circular-progress')), findsOneWidget);
    expect(find.byKey(const Key('page4-standard-snackbar')), findsOneWidget);
    expect(find.byKey(const Key('page4-floating-snackbar')), findsOneWidget);
    expect(find.byKey(const Key('page4-info-dialog')), findsOneWidget);
    expect(find.byKey(const Key('page4-confirm-dialog')), findsOneWidget);
  });

  testWidgets('indeterminate checkbox cycles through real tri-state values', (
    tester,
  ) async {
    await pumpLab(tester);
    final finder = find.byKey(const Key('page4-checkbox-mixed'));
    await tester.ensureVisible(finder);
    await tester.pump();

    expect(tester.widget<CheckboxListTile>(finder).value, isNull);
    await tester.tap(finder);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(finder).value, isFalse);
    await tester.tap(finder);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(finder).value, isTrue);
  });

  testWidgets('task progress freezes while paused and can be canceled', (
    tester,
  ) async {
    await pumpLab(tester);
    final start = find.byKey(const Key('page4-task-start'));
    await tester.ensureVisible(start);
    await tester.pump();
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byKey(const Key('page4-indeterminate-progress')),
      findsOneWidget,
    );

    final pause = find.byKey(const Key('page4-task-pause'));
    await tester.ensureVisible(pause);
    await tester.pump();
    await tester.tap(pause);
    await tester.pump();
    final before = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('page4-linear-progress')),
        )
        .value!;
    await tester.pump(const Duration(seconds: 1));
    final after = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('page4-linear-progress')),
        )
        .value!;
    expect(after, closeTo(before, 0.0001));

    final resume = find.byKey(const Key('page4-task-resume'));
    await tester.ensureVisible(resume);
    await tester.pump();
    await tester.tap(resume);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final resumed = tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('page4-linear-progress')),
        )
        .value!;
    expect(resumed, greaterThan(after));

    final cancel = find.byKey(const Key('page4-task-cancel'));
    await tester.ensureVisible(cancel);
    await tester.pump();
    await tester.tap(cancel);
    await tester.pump();
    expect(find.text('Canceled'), findsWidgets);
  });

  testWidgets('deterministic failure exposes retry at 65 percent', (
    tester,
  ) async {
    await pumpLab(tester);
    final failureSwitch = find.byKey(
      const Key('page4-simulate-failure'),
    );
    await tester.ensureVisible(failureSwitch);
    await tester.pump();
    await tester.tap(failureSwitch);
    await tester.pump();
    await tester.tap(find.byKey(const Key('page4-task-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3400));
    await tester.pump();

    expect(find.text('Failed'), findsWidgets);
    expect(find.byKey(const Key('page4-task-retry')), findsOneWidget);
    expect(
      find.text('The deterministic failure was triggered at 65%.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('page4-linear-progress')),
          )
          .value,
      closeTo(0.65, 0.0001),
    );

    await tester.ensureVisible(failureSwitch);
    await tester.pump();
    await tester.tap(failureSwitch);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(failureSwitch).value, isFalse);

    final retry = find.byKey(const Key('page4-task-retry'));
    await tester.ensureVisible(retry);
    await tester.pump();
    await tester.tap(retry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5100));
    await tester.pump();
    expect(find.text('Succeeded'), findsWidgets);
  });

  testWidgets('narrow layout supports high contrast and 200 percent text', (
    tester,
  ) async {
    await pumpLab(tester, size: const Size(320, 900));

    final contrast = find.byKey(const Key('page4-high-contrast'));
    await tester.ensureVisible(contrast);
    await tester.pump();
    await tester.tap(contrast);
    await tester.pump();
    await tester.tap(find.text('200%'));
    await tester.pump();

    expect(find.text('Weekly activity summary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy feedback variants and bottom sheet remain available', (
    tester,
  ) async {
    await pumpLab(tester);

    final standard = find.byKey(const Key('page4-standard-snackbar'));
    await tester.ensureVisible(standard);
    await tester.tap(standard);
    await tester.pump();
    expect(find.text('This is a standard SnackBar message.'), findsOneWidget);

    final floating = find.byKey(const Key('page4-floating-snackbar'));
    await tester.ensureVisible(floating);
    await tester.tap(floating);
    await tester.pump();
    expect(find.text('Action completed successfully.'), findsOneWidget);

    final bottomSheet = find.byKey(const Key('page4-bottom-sheet'));
    await tester.ensureVisible(bottomSheet);
    await tester.tap(bottomSheet);
    await tester.pumpAndSettle();
    expect(find.text('Review current selection'), findsOneWidget);
  });
}
