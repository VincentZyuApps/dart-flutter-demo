import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:system_info_vincentzyu/system_info_vincentzyu.dart';

class AndroidHomeWidgetService {
  AndroidHomeWidgetService._();

  static const MethodChannel _channel = MethodChannel(
    'dart_flutter_demo/home_widget',
  );

  static Future<void> syncSystemInfoWidget(SystemInfoSnapshot? snapshot) async {
    if (!Platform.isAndroid || snapshot == null) return;
    try {
      await _channel.invokeMethod<void>('syncHomeWidget', <String, Object?>{
        'diskPercent': snapshot.diskUsedPercent?.round(),
        'memoryPercent': snapshot.memoryUsedPercent?.round(),
        'uptimeSeconds': snapshot.uptime?.inSeconds,
      });
    } catch (_) {
      // Widget sync should stay best-effort and never break the page refresh.
    }
  }
}
