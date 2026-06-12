import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class AndroidHomeWidgetService {
  AndroidHomeWidgetService._();

  static const MethodChannel _channel = MethodChannel(
    'dart_flutter_demo/system_info',
  );

  static Future<void> syncSystemInfoWidget() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('syncHomeWidget');
    } catch (_) {
      // Widget sync should stay best-effort and never break the page refresh.
    }
  }
}
