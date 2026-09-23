import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/system_info_service.dart';
import 'services/desktop_integration_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  desktopRequestLogger = logDesktopShellRequest;
  if (!await DesktopIntegrationService.claimSingleInstance(args)) {
    exit(0);
  }
  DesktopIntegrationService.handleLaunchArguments(args);
  runApp(const FlutterShowcaseApp());
}
