import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/system_info_service.dart';
import 'services/taskbar_integration_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  desktopRequestLogger = logDesktopShellRequest;
  if (!await TaskbarIntegrationService.claimSingleInstance(args)) {
    exit(0);
  }
  TaskbarIntegrationService.handleLaunchArguments(args);
  runApp(const FlutterShowcaseApp());
}
