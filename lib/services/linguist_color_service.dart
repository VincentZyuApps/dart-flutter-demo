import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class LinguistColorService {
  LinguistColorService._() {
    fetchColors();
  }

  static final LinguistColorService instance = LinguistColorService._();

  static const Color defaultColor = Color(0xFF8B949E); // GitHub 次要中性灰

  final Map<String, Color> _colorCache = {};
  bool _isLoading = false;

  final ValueNotifier<int> versionNotifier = ValueNotifier<int>(0);

  Color getColor(String? language) {
    if (language == null || language.trim().isEmpty) {
      return defaultColor;
    }
    return _colorCache[language.trim()] ?? defaultColor;
  }

  Future<void> fetchColors() async {
    if (_isLoading || _colorCache.isNotEmpty) return;
    _isLoading = true;

    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://raw.githubusercontent.com/ozh/github-colors/master/colors.json',
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'dart_flutter_demo/0.6');
      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = await utf8.decodeStream(response);
        final dynamic json = jsonDecode(body);
        if (json is Map<String, dynamic>) {
          for (final entry in json.entries) {
            final dynamic val = entry.value;
            if (val is Map && val['color'] is String) {
              final hex = (val['color'] as String).replaceAll('#', '');
              if (hex.length == 6) {
                final intVal = int.tryParse('FF$hex', radix: 16);
                if (intVal != null) {
                  _colorCache[entry.key] = Color(intVal);
                }
              }
            }
          }
          versionNotifier.value++;
        }
      }
    } catch (_) {
      // 保持 simple & stupid: 网络异常或离线时不阻断，未知或获取失败直接展示默认灰色
    } finally {
      client.close(force: true);
      _isLoading = false;
    }
  }
}
