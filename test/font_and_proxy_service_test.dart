import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_flutter_demo/services/font_service.dart';
import 'package:dart_flutter_demo/services/network_proxy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FontService Tests', () {
    test('FontService contains all 10 curated fonts with valid metadata', () {
      final service = FontService.instance;
      expect(AppFontFamily.values.length, 10);

      for (final font in AppFontFamily.values) {
        expect(font.id.isNotEmpty, isTrue);
        expect(font.displayName.isNotEmpty, isTrue);
        expect(font.category.isNotEmpty, isTrue);
        expect(font.description.isNotEmpty, isTrue);

        service.setFont(font);
        expect(service.currentFont, font);
      }

      // 验证原生系统字体 applyFont 返回原生 TextTheme
      const baseTheme = TextTheme();
      final systemTheme = service.applyFont(baseTheme, AppFontFamily.system);
      expect(systemTheme, equals(baseTheme));
    });
  });

  group('NetworkProxyService Tests', () {
    test('NetworkProxyService 3-state proxy switching and summary', () {
      final proxy = NetworkProxyService.instance;

      proxy.setMode(ProxyMode.direct);
      expect(proxy.mode, ProxyMode.direct);
      expect(proxy.summary, contains('直连'));

      proxy.setMode(ProxyMode.system);
      expect(proxy.mode, ProxyMode.system);
      expect(proxy.summary, contains('系统'));

      proxy.setMode(ProxyMode.manual);
      proxy.setManualUrl('http://127.0.0.1:7890');
      expect(proxy.mode, ProxyMode.manual);
      expect(proxy.summary, contains('7890'));

      // 验证 HttpOverrides
      final overrides = AppHttpOverrides(
        mode: ProxyMode.manual,
        proxyUrl: 'http://127.0.0.1:7890',
      );
      expect(overrides.mode, ProxyMode.manual);
      expect(overrides.proxyUrl, 'http://127.0.0.1:7890');
    });
  });
}
