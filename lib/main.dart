import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/command_line_service.dart';
import 'services/system_info_service.dart';
import 'services/desktop_integration_service.dart';

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
  runApp(const FlutterShowcaseApp());
}
