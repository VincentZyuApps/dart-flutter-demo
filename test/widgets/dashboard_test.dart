import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_flutter_demo/widgets/dashboard/sunflower_toggle.dart';
import 'package:dart_flutter_demo/widgets/dashboard/smooth_wave_chart.dart';
import 'package:dart_flutter_demo/widgets/dashboard/system_monitor_dashboard.dart';
import 'package:dart_flutter_demo/services/system_monitor_service.dart';

void main() {
  group('Sunflower Dashboard Widgets', () {
    testWidgets('SunflowerToggle switches state and triggers callback', (tester) async {
      bool running = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SunflowerToggle(
                  running: running,
                  onToggle: () {
                    setState(() {
                      running = !running;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byType(SunflowerToggle), findsOneWidget);

      await tester.tap(find.byType(SunflowerToggle));
      await tester.pumpAndSettle();

      expect(running, isTrue);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('SmoothWaveChart renders without exceptions for empty and populated data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SmoothWaveChart(
                  values: [],
                  color: Colors.blue,
                ),
                SmoothWaveChart(
                  values: [10.0, 50.0, 25.0, 80.0, 40.0],
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SmoothWaveChart), findsNWidgets(2));
    });

    testWidgets('SystemMonitorDashboard renders master card and four metrics', (tester) async {
      final service = SystemMonitorService.instance;
      service.stopMonitoring();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SystemMonitorDashboard(
                hostInfo: 'Test-Host',
                osInfo: 'Test-OS',
              ),
            ),
          ),
        ),
      );

      expect(find.text('实时系统监视器'), findsNothing); // 标题在 page0 中
      expect(find.text('监视已待机'), findsOneWidget);
      expect(find.text('CPU 负载'), findsOneWidget);
      expect(find.text('物理内存'), findsOneWidget);
      expect(find.text('网络上行'), findsOneWidget);
      expect(find.text('网络下行'), findsOneWidget);
    });
  });
}
