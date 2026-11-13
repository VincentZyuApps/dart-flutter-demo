import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_flutter_demo/services/app_config_service.dart';
import 'package:dart_flutter_demo/services/font_service.dart';
import 'package:dart_flutter_demo/services/network_proxy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfigService tests', () {
    final cfg = AppConfigService.instance;

    test('initial defaults are standard', () {
      expect(cfg.themeMode, ThemeMode.system);
      expect(cfg.fontFamily, AppFontFamily.system);
      expect(cfg.proxyMode, ProxyMode.system);
      expect(cfg.manualProxyUrl, NetworkProxyService.defaultManualProxy);
      expect(cfg.enableLazerHud, isFalse);
      expect(cfg.detailedLazerHud, isTrue);
      expect(cfg.sources.length, 3);
    });

    test('resolveConfigFile returns a valid File object', () async {
      final file = await cfg.resolveConfigFile();
      expect(file, isA<File>());
      expect(file.path.endsWith('config.yaml'), isTrue);
    });

    test('save and load cycle updates properties', () async {
      cfg.githubToken = 'ghp_mock_token_12345';
      cfg.themeMode = ThemeMode.dark;
      cfg.fontFamily = AppFontFamily.jetBrainsMono;
      await cfg.save();

      // 重置内存字段并从文件重新加载
      cfg.githubToken = '';
      cfg.themeMode = ThemeMode.system;
      await cfg.load();

      expect(cfg.githubToken, 'ghp_mock_token_12345');
      expect(cfg.themeMode, ThemeMode.dark);
      expect(cfg.fontFamily, AppFontFamily.jetBrainsMono);
    });
  });
}
