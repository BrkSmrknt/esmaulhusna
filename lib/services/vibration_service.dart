import 'package:vibration/vibration.dart';

class VibrationService {
  static bool? _hasVibrator;
  static bool? _hasAmplitudeControl;

  static Future<void> init() async {
    _hasVibrator = await Vibration.hasVibrator();
    _hasAmplitudeControl = await Vibration.hasAmplitudeControl();
  }

  static Future<void> vibrate({int duration = 50}) async {
    if (_hasVibrator == null) await init();
    if (_hasVibrator != true) return;

    try {
      if (_hasAmplitudeControl == true) {
        Vibration.vibrate(duration: duration, amplitude: 128);
      } else {
        Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      // Fallback
      try {
        Vibration.vibrate(duration: duration);
      } catch (_) {}
    }
  }

  static Future<void> vibrateLight() async {
    await vibrate(duration: 30);
  }

  static Future<void> vibrateMedium() async {
    await vibrate(duration: 80);
  }

  static Future<void> vibrateHeavy() async {
    await vibrate(duration: 200);
  }

  static Future<void> vibratePattern() async {
    if (_hasVibrator == null) await init();
    if (_hasVibrator != true) return;

    try {
      Vibration.vibrate(pattern: [0, 50, 30, 50], intensities: [0, 128, 0, 255]);
    } catch (e) {
      await vibrate(duration: 100);
    }
  }
}
