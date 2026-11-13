import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_config_service.dart';
import 'services/app_performance.dart';
import 'services/command_line_service.dart';
import 'services/desktop_integration_service.dart';
import 'services/font_service.dart';
import 'services/network_proxy_service.dart';
import 'services/system_info_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final CommandLineRequest request = CommandLineRequest.parse(args);
  if (request.hasError) {
    stderr.writeln(request.error);
    stdout.write(CommandLineService.usage);
    exit(64);
  }
  if (request.isCommand) {
    exit(await CommandLineService.run(request));
  }

  desktopRequestLogger = logDesktopShellRequest;
  DesktopIntegrationService.configureKdeWaylandFocus(args);
  if (!await DesktopIntegrationService.claimSingleInstance(args)) {
    exit(0);
  }
  DesktopIntegrationService.handleLaunchArguments(args);

  // 初始化全局持久化配置
  await AppConfigService.instance.load();
  themeNotifier.value = AppConfigService.instance.themeMode;
  FontService.instance.setFont(AppConfigService.instance.fontFamily);
  NetworkProxyService.instance.setMode(AppConfigService.instance.proxyMode);
  NetworkProxyService.instance.setManualUrl(AppConfigService.instance.manualProxyUrl);
  showPerformanceHudNotifier.value = AppConfigService.instance.enableLazerHud;
  detailedPerformanceHudNotifier.value = AppConfigService.instance.detailedLazerHud;

  runApp(const FlutterShowcaseApp());
}
