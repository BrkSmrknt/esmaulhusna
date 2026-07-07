import 'package:flutter/services.dart';

class VibrationService {
  static Future<void> init() async {}

  static Future<void> vibrateLight() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> vibrateMedium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> vibrateHeavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> vibratePattern() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
