import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_flutter_demo/services/linguist_color_service.dart';

void main() {
  group('LinguistColorService tests', () {
    final service = LinguistColorService.instance;

    test('defaultColor is GitHub neutral grey', () {
      expect(LinguistColorService.defaultColor, const Color(0xFF8B949E));
    });

    test('getColor returns default grey for null, empty or unknown language', () {
      expect(service.getColor(null), LinguistColorService.defaultColor);
      expect(service.getColor(''), LinguistColorService.defaultColor);
      expect(service.getColor('   '), LinguistColorService.defaultColor);
      expect(service.getColor('CompletelyUnknownLanguage123'), LinguistColorService.defaultColor);
    });

    test('versionNotifier initialized', () {
      expect(service.versionNotifier.value, greaterThanOrEqualTo(0));
    });
  });
}
