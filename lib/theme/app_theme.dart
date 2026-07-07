import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Uygulamanın renk paleti. Tüm ekranlar renklerini buradan alır; böylece
/// karanlık ve aydınlık mod tek noktadan yönetilir.
///
/// [onBg] yardımcısı, arka planın üstüne binen ön plan rengini (karanlıkta
/// beyaz, aydınlıkta koyu) verilen opaklıkla döndürür. Mevcut ekranlardaki
/// `Colors.white.withValues(alpha: x)` kullanımları buna karşılık gelir ve
/// her iki modda da tutarlı çalışır.
@immutable
class AppPalette {
  final bool isDark;
  final List<Color> bg;
  final Color fg;
  final Color dialogBg;
  final List<Color> buttonGradient;
  final Color buttonGlow;
  final Color progressTrack;

  const AppPalette({
    required this.isDark,
    required this.bg,
    required this.fg,
    required this.dialogBg,
    required this.buttonGradient,
    required this.buttonGlow,
    required this.progressTrack,
  });

  Color onBg(double opacity) => fg.withValues(alpha: opacity);
  Color get textPrimary => fg;

  static const AppPalette dark = AppPalette(
    isDark: true,
    bg: [
      Color(0xFF0D0D0D),
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0D0D0D),
    ],
    fg: Colors.white,
    dialogBg: Color(0xFF1E1E1E),
    buttonGradient: [Color(0xFF2E7D63), Color(0xFF1B5E4F), Color(0xFF0C3A30)],
    buttonGlow: Color(0xFF2E7D63),
    progressTrack: Color(0xFF2A2A2A),
  );

  /// Aydınlık mod: sıcak krem → şeftali → leylak → gökyüzü mavisi geçişli,
  /// canlı ama okunaklı bir palet.
  static const AppPalette light = AppPalette(
    isDark: false,
    bg: [
      Color(0xFFFFF4E8),
      Color(0xFFFFDDC7),
      Color(0xFFEBDAF7),
      Color(0xFFCFE8FF),
    ],
    fg: Color(0xFF2A211C),
    dialogBg: Color(0xFFFFFBF5),
    buttonGradient: [Color(0xFF3ECB96), Color(0xFF1FA576), Color(0xFF14805C)],
    buttonGlow: Color(0xFF3ECB96),
    progressTrack: Color(0xFFE7DACE),
  );
}

/// Aktif temayı tutan ve değişince dinleyicilerini uyaran kontrolcü.
class ThemeController extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;
  AppPalette get palette => _isDark ? AppPalette.dark : AppPalette.light;

  Future<void> load() async {
    _isDark = await StorageService.getDarkMode();
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (value == _isDark) return;
    _isDark = value;
    notifyListeners();
    await StorageService.setDarkMode(value);
  }
}

/// Uygulama genelinde tek kontrolcü örneği.
final ThemeController appTheme = ThemeController();

/// Aktif paleti alt ağaca (pushlanan rotalar dahil) taşıyan InheritedWidget.
class ThemeScope extends InheritedWidget {
  final AppPalette palette;

  const ThemeScope({
    super.key,
    required this.palette,
    required super.child,
  });

  static AppPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope?.palette ?? AppPalette.dark;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.palette != palette;
}
