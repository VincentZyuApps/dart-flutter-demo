import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/taskbar_integration_service.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!await TaskbarIntegrationService.claimSingleInstance(args)) {
    exit(0);
  }
  TaskbarIntegrationService.handleLaunchArguments(args);
  runApp(const FlutterShowcaseApp());
}
