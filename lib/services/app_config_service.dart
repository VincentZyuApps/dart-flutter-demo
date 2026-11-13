import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import 'font_service.dart';
import 'network_proxy_service.dart';

class AppConfigService {
  AppConfigService._();

  static final AppConfigService instance = AppConfigService._();

  static const String appConfigFolderName = 'dart_flutter_demo';
  static const String configFileName = 'config.yaml';

  static const List<String> defaultSources = <String>[
    'https://github.com/VincentZyu233?tab=repositories',
    'https://github.com/orgs/VincentZyuApps/repositories',
    'https://github.com/VincentZyuLive?tab=repositories',
  ];

  ThemeMode themeMode = ThemeMode.system;
  AppFontFamily fontFamily = AppFontFamily.system;
  ProxyMode proxyMode = ProxyMode.system;
  String manualProxyUrl = NetworkProxyService.defaultManualProxy;
  bool enableLazerHud = false;
  bool detailedLazerHud = true;
  String githubToken = '';
  List<String> sources = List.from(defaultSources);

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);
  File? _resolvedConfigFile;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<File> resolveConfigFile() async {
    if (_resolvedConfigFile != null) return _resolvedConfigFile!;

    // 1. 便携模式探测：如果与可执行文件同级存在 config.yaml，优先使用
    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final portableFile = File('${exeDir.path}${Platform.pathSeparator}$configFileName');
      if (await portableFile.exists()) {
        _resolvedConfigFile = portableFile;
        return portableFile;
      }
    } catch (_) {}

    // 2. 操作系统规范目录
    Directory targetDir;
    try {
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          targetDir = Directory('$appData${Platform.pathSeparator}$appConfigFolderName');
        } else {
          final sup = await getApplicationSupportDirectory();
          targetDir = sup;
        }
      } else if (Platform.isLinux) {
        final xdg = Platform.environment['XDG_CONFIG_HOME'];
        final home = Platform.environment['HOME'];
        if (xdg != null && xdg.isNotEmpty) {
          targetDir = Directory('$xdg${Platform.pathSeparator}$appConfigFolderName');
        } else if (home != null && home.isNotEmpty) {
          targetDir = Directory('$home${Platform.pathSeparator}.config${Platform.pathSeparator}$appConfigFolderName');
        } else {
          targetDir = await getApplicationSupportDirectory();
        }
      } else {
        targetDir = await getApplicationSupportDirectory();
      }
    } catch (_) {
      targetDir = Directory.current;
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    _resolvedConfigFile = File('${targetDir.path}${Platform.pathSeparator}$configFileName');
    return _resolvedConfigFile!;
  }

  Future<void> load() async {
    final file = await resolveConfigFile();
    if (!await file.exists()) {
      _initialized = true;
      return;
    }

    try {
      final content = await file.readAsString();
      final dynamic doc = loadYaml(content);
      if (doc is Map) {
        // Appearance
        final appearance = doc['appearance'];
        if (appearance is Map) {
          final tMode = appearance['theme_mode']?.toString();
          if (tMode == 'light') themeMode = ThemeMode.light;
          if (tMode == 'dark') themeMode = ThemeMode.dark;
          if (tMode == 'system') themeMode = ThemeMode.system;

          final fId = appearance['font_family']?.toString();
          if (fId != null) {
            for (final f in AppFontFamily.values) {
              if (f.id == fId) {
                fontFamily = f;
                break;
              }
            }
          }
        }

        // Network
        final network = doc['network'];
        if (network is Map) {
          final pMode = network['proxy_mode']?.toString();
          if (pMode == 'direct') proxyMode = ProxyMode.direct;
          if (pMode == 'system') proxyMode = ProxyMode.system;
          if (pMode == 'manual') proxyMode = ProxyMode.manual;

          final mUrl = network['manual_proxy_url']?.toString();
          if (mUrl != null && mUrl.isNotEmpty) {
            manualProxyUrl = mUrl;
          }
        }

        // Performance
        final perf = doc['performance'];
        if (perf is Map) {
          if (perf['enable_lazer_hud'] is bool) {
            enableLazerHud = perf['enable_lazer_hud'] as bool;
          }
          if (perf['detailed_lazer_hud'] is bool) {
            detailedLazerHud = perf['detailed_lazer_hud'] as bool;
          }
        }

        // GitHub
        final gh = doc['github'];
        if (gh is Map) {
          final tok = gh['token']?.toString();
          if (tok != null) {
            githubToken = tok.trim();
          }

          final sList = gh['sources'];
          if (sList is List) {
            final parsed = sList.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
            if (parsed.isNotEmpty) {
              sources = parsed;
            }
          }
        }
      }
    } catch (_) {
      // 容灾：解析失败时沿用默认配置
    }

    _initialized = true;
    changeNotifier.value++;
  }

  Future<void> save() async {
    final file = await resolveConfigFile();
    final buffer = StringBuffer();

    buffer.writeln('# DartFlutterDemo 全局配置文件 (0.6.x)');
    buffer.writeln('version: 1');
    buffer.writeln('');
    buffer.writeln('appearance:');
    buffer.writeln('  theme_mode: ${themeMode.name}');
    buffer.writeln('  font_family: ${fontFamily.id}');
    buffer.writeln('');
    buffer.writeln('network:');
    buffer.writeln('  proxy_mode: ${proxyMode.name}');
    buffer.writeln('  manual_proxy_url: "$manualProxyUrl"');
    buffer.writeln('');
    buffer.writeln('performance:');
    buffer.writeln('  enable_lazer_hud: $enableLazerHud');
    buffer.writeln('  detailed_lazer_hud: $detailedLazerHud');
    buffer.writeln('');
    buffer.writeln('github:');
    buffer.writeln('  token: "$githubToken"');
    buffer.writeln('  sources:');
    for (final s in sources) {
      buffer.writeln('    - "$s"');
    }

    await file.writeAsString(buffer.toString(), flush: true);
    changeNotifier.value++;
  }
}
