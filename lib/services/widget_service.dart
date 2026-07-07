import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/esma_data.dart';
import 'storage_service.dart';

/// Ana ekran widget'ı ile uygulama arasındaki köprü.
///
/// Uygulama, mevcut zikir durumunu [update] ile widget'a yansıtır. Kullanıcı
/// widget üzerindeki "+ Çek" butonuna bastığında [zikirBackgroundCallback]
/// arka planda (uygulama kapalıyken bile) çalışır, sayacı düşürür, hem
/// widget'ı hem uygulama geçmişini günceller.
class WidgetService {
  // Uygulama ile arka plan callback'inin paylaştığı anlık durum anahtarları
  // (varsayılan SharedPreferences deposunda tutulur).
  static const String kIndex = 'widget_index';
  static const String kTarget = 'widget_target';
  static const String kCompleted = 'widget_completed';

  static const String _androidName = 'EsmaWidgetProvider';
  static const String _qualifiedAndroidName =
      'com.esmaulhusna.esmaulhusna.EsmaWidgetProvider';

  /// Arka plan tıklama callback'ini kaydeder. Uygulama başlarken çağrılmalı.
  static Future<void> init() async {
    try {
      await HomeWidget.registerInteractivityCallback(zikirBackgroundCallback);
    } catch (_) {
      // Platform desteklemiyorsa (ör. test) sessizce geç.
    }
  }

  /// Mevcut zikir durumunu widget'a yazar ve widget'ı yeniler. Aynı zamanda
  /// arka plan callback'inin okuyacağı anlık durumu kaydeder.
  static Future<void> update({
    required int index,
    required int target,
    required int completed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kIndex, index);
    await prefs.setInt(kTarget, target);
    await prefs.setInt(kCompleted, completed);
    await render(index: index, target: target, completed: completed);
  }

  /// Verilen duruma göre widget alanlarını doldurur ve yeniden çizdirir.
  static Future<void> render({
    required int index,
    required int target,
    required int completed,
  }) async {
    final safeIndex =
        (index >= 0 && index < EsmaData.esmalar.length) ? index : 0;
    final esma = EsmaData.esmalar[safeIndex];
    final remaining = target > 0 ? (target - completed).clamp(0, target) : 0;
    final done = target > 0 && remaining <= 0;
    final progress =
        target > 0 ? ((completed / target) * 100).round().clamp(0, 100) : 0;

    // Widget güncellemesi hiçbir koşulda uygulamayı çökertmemeli (ör. test
    // ortamında platform kanalı yoksa sessizce geç).
    try {
      await HomeWidget.saveWidgetData<String>('w_arabic', esma.arapca);
      await HomeWidget.saveWidgetData<String>('w_latin', esma.latin);
      await HomeWidget.saveWidgetData<String>(
          'w_remaining', done ? '✓' : '$remaining');
      await HomeWidget.saveWidgetData<String>(
          'w_sub', done ? 'tamamlandı' : 'kalan');
      await HomeWidget.saveWidgetData<String>('w_target', '$target');
      await HomeWidget.saveWidgetData<String>('w_progress', '$progress');
      await HomeWidget.saveWidgetData<String>('w_done', done ? '1' : '0');

      await HomeWidget.updateWidget(
        androidName: _androidName,
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (_) {
      // yoksay
    }
  }
}

/// Widget'taki "+ Çek" butonuna basılınca arka planda çalışır.
@pragma('vm:entry-point')
Future<void> zikirBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host != 'cek') return;

  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt(WidgetService.kIndex) ?? 0;
  final safeIndex =
      (index >= 0 && index < EsmaData.esmalar.length) ? index : 0;
  final esma = EsmaData.esmalar[safeIndex];
  final target = prefs.getInt(WidgetService.kTarget) ?? esma.ebced;
  var completed = prefs.getInt(WidgetService.kCompleted) ?? 0;

  if (completed < target) {
    completed++;
    await prefs.setInt(WidgetService.kCompleted, completed);

    // Uygulama geçmişini de güncelle ki uygulama açılınca tutarlı olsun.
    if (completed >= target) {
      await StorageService.incrementCompletion(safeIndex, esma.latin, target);
    } else {
      await StorageService.updateZikirCount(
          safeIndex, esma.latin, target, completed);
    }
  }

  await WidgetService.render(
      index: safeIndex, target: target, completed: completed);
}
