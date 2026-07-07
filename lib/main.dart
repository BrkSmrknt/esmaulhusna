import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/zikir_screen.dart';
import 'services/vibration_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VibrationService.init();
  await WidgetService.init();
  await appTheme.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Kenardan kenara mod: içerik durum ve gezinme çubuklarının arkasına
  // taşar, SafeArea sayesinde etkileşimli öğeler görünür kalır.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    appTheme.addListener(_onThemeChanged);
    _applySystemUiStyle();
  }

  @override
  void dispose() {
    appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(_applySystemUiStyle);
  }

  void _applySystemUiStyle() {
    final brightness =
        appTheme.isDark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: brightness,
      systemNavigationBarIconBrightness: brightness,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = appTheme.palette;
    return ThemeScope(
      palette: palette,
      child: MaterialApp(
        title: 'Esma-ül Hüsnâ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: palette.isDark ? Brightness.dark : Brightness.light,
          primarySwatch: Colors.orange,
          scaffoldBackgroundColor: palette.bg.first,
        ),
        home: const ZikirScreen(),
      ),
    );
  }
}
