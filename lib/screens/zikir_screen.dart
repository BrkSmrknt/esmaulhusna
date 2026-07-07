import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../data/esma_data.dart';
import '../models/esma_model.dart';
import '../services/storage_service.dart';
import '../services/vibration_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_progress.dart';
import '../widgets/tap_glow_effect.dart';
import '../widgets/milestone_float.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'names_list_screen.dart';
import 'settings_screen.dart';

class ZikirScreen extends StatefulWidget {
  final int initialIndex;

  const ZikirScreen({super.key, this.initialIndex = 0});

  @override
  State<ZikirScreen> createState() => _ZikirScreenState();
}

class _ZikirScreenState extends State<ZikirScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _accentLight = Color(0xFFFF8E53);

  /// Mevcut palet; her [build] başında güncellenir ve yardımcı metotlarda
  /// kullanılır.
  AppPalette _p = AppPalette.dark;

  late int _currentIndex;
  late int _remaining;
  bool _isFavorited = false;
  bool _vibrationEnabled = true;
  int _customCount = 33;
  bool _useEbced = true;

  /// İsim geçiş animasyonunun yönü: 1 = sonraki, -1 = önceki.
  int _navDirection = 1;

  final List<_RippleData> _ripples = [];
  final List<_MilestoneData> _milestones = [];
  int _effectSeq = 0;

  static const List<double> _milestoneThresholds = [
    0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9,
  ];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _remaining = _currentEsma.ebced;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    VibrationService.init();
    WidgetsBinding.instance.addObserver(this);
    _refreshState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı widget'tan zikir çekmiş olabilir; uygulama öne gelince
    // durumu depodan yeniden yükleyerek senkron kal.
    if (state == AppLifecycleState.resumed) {
      _refreshState();
    }
  }

  /// Mevcut zikir durumunu ana ekran widget'ına yansıtır.
  void _syncWidget() {
    WidgetService.update(
      index: _currentIndex,
      target: _totalCount,
      completed: _completed,
    );
  }

  /// Ayarları ve mevcut isim için kayıtlı ilerlemeyi yükler. Kayıtlı hedef
  /// ebced ya da özel sayıyla eşleşiyorsa o mod ve kalan sayı geri getirilir;
  /// eşleşmiyorsa sayaç mevcut hedefe göre sıfırdan başlar.
  Future<void> _refreshState() async {
    final index = _currentIndex;
    final vibration = await StorageService.getVibrationEnabled();
    final favorited = await StorageService.isFavorite(index);
    final customCount = await StorageService.getCustomCount();
    final history = await StorageService.getHistory();

    if (!mounted || index != _currentIndex) return;

    var useEbced = _useEbced;
    int? savedRemaining;
    final ebced = _currentEsma.ebced;

    final matches = history.where((h) => h.esmaIndex == index);
    if (matches.isNotEmpty) {
      final entry = matches.first;
      if (!entry.isCompleted && entry.completedCount > 0) {
        if (entry.targetCount == ebced) {
          useEbced = true;
          savedRemaining = entry.targetCount - entry.completedCount;
        } else if (entry.targetCount == customCount) {
          useEbced = false;
          savedRemaining = entry.targetCount - entry.completedCount;
        }
      }
    }

    setState(() {
      _vibrationEnabled = vibration;
      _isFavorited = favorited;
      _customCount = customCount;
      _useEbced = useEbced;
      final total = useEbced ? ebced : customCount;
      _remaining =
          (savedRemaining != null && savedRemaining > 0 && savedRemaining <= total)
              ? savedRemaining
              : total;
    });
    _syncWidget();
  }

  EsmaModel get _currentEsma => EsmaData.esmalar[_currentIndex];

  int get _totalCount => _useEbced ? _currentEsma.ebced : _customCount;
  int get _completed => _totalCount - _remaining;

  void _onTapDown(TapDownDetails details) {
    if (_remaining <= 0) return;

    if (_vibrationEnabled) {
      VibrationService.vibrateLight();
    }

    _pulseController.forward().then((_) => _pulseController.reverse());

    final total = _totalCount;
    final oldCompleted = _completed;
    final position = details.localPosition;

    setState(() {
      _remaining--;
      _ripples.add(_RippleData(id: _effectSeq++, position: position));

      if (total > 0 &&
          _remaining > 0 &&
          _crossedMilestone(oldCompleted, _completed, total)) {
        _milestones.add(_MilestoneData(id: _effectSeq++, value: _remaining));
      }
    });

    if (_remaining <= 0) {
      StorageService.incrementCompletion(
        _currentIndex,
        _currentEsma.latin,
        _totalCount,
      );
      _showCompletionDialog();
    } else {
      StorageService.updateZikirCount(
        _currentIndex,
        _currentEsma.latin,
        _totalCount,
        _completed,
      );
    }
    _syncWidget();
  }

  void _showCompletionDialog() {
    if (_vibrationEnabled) {
      VibrationService.vibrateHeavy();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: _p.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _accent, width: 2),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: _accent, size: 28),
              const SizedBox(width: 8),
              Text(
                'MashaAllah!',
                style: TextStyle(
                  color: _p.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentEsma.latin,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalCount defa tamamlandı!',
                style: TextStyle(color: _p.onBg(0.7), fontSize: 16),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetCurrentZikir();
                  },
                  child: Text('Tekrarla',
                      style: TextStyle(color: _p.onBg(0.5))),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _changeEsma(1);
                  },
                  child: const Text('Sonraki İsim',
                      style: TextStyle(color: _accent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _crossedMilestone(int oldCompleted, int newCompleted, int total) {
    final oldProg = oldCompleted / total;
    final newProg = newCompleted / total;
    for (final t in _milestoneThresholds) {
      if (oldProg < t && newProg >= t) return true;
    }
    return false;
  }

  void _removeRipple(int id) {
    setState(() {
      _ripples.removeWhere((d) => d.id == id);
    });
  }

  void _removeMilestone(int id) {
    setState(() {
      _milestones.removeWhere((d) => d.id == id);
    });
  }

  void _changeEsma(int delta) {
    final len = EsmaData.esmalar.length;
    _jumpToEsma(
      (_currentIndex + delta + len) % len,
      direction: delta >= 0 ? 1 : -1,
    );
  }

  void _jumpToEsma(int index, {int? direction}) {
    if (index == _currentIndex) return;
    setState(() {
      _navDirection = direction ?? (index > _currentIndex ? 1 : -1);
      _currentIndex = index;
      _remaining = _totalCount;
      _ripples.clear();
      _milestones.clear();
    });
    _refreshState();
  }

  /// Alt ekranlardan biri isim seçerek kapanırsa o isme atlar; kapanış sonrası
  /// favori/geçmiş/ayar değişikliklerini de tazeler.
  Future<void> _openScreen(Widget screen) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (!mounted) return;
    if (result != null) {
      _jumpToEsma(result);
    } else {
      _refreshState();
    }
  }

  void _toggleFavorite() async {
    await StorageService.toggleFavorite(_currentIndex);
    _isFavorited = !_isFavorited;
    setState(() {});
  }

  void _resetCurrentZikir() {
    setState(() {
      _remaining = _totalCount;
      _ripples.clear();
      _milestones.clear();
    });
    StorageService.updateZikirCount(
      _currentIndex,
      _currentEsma.latin,
      _totalCount,
      0,
    );
    _syncWidget();
  }

  void _switchTargetMode(bool ebced) {
    if (ebced == _useEbced) return;
    final oldCompleted = _completed;
    setState(() {
      _useEbced = ebced;
      final newTotal = _totalCount;
      final clamped = oldCompleted > newTotal ? newTotal : oldCompleted;
      _remaining = newTotal - clamped;
      _ripples.clear();
      _milestones.clear();
    });
    StorageService.updateZikirCount(
      _currentIndex,
      _currentEsma.latin,
      _totalCount,
      _completed,
    );
    _syncWidget();
  }

  @override
  Widget build(BuildContext context) {
    _p = ThemeScope.of(context);
    final progress = _totalCount > 0 ? _completed / _totalCount : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _p.bg,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final w = constraints.maxWidth;
              final isSmall = h < 700;

              // Tablet ve geniş ekranlarda içerik ortada, okunur bir
              // genişlikte kalır; telefonlarda tüm genişlik kullanılır.
              final contentWidth = math.min(w, 520.0);
              final buttonSize = math
                  .min(contentWidth * 0.72, h * 0.38)
                  .clamp(180.0, 360.0)
                  .toDouble();
              final innerSize = buttonSize * 0.77;
              final arabicFont = (h * 0.054).clamp(30.0, 56.0).toDouble();
              final latinFont = (h * 0.028).clamp(17.0, 27.0).toDouble();
              final remainFont = innerSize * 0.30;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      _buildTopBar(isSmall),
                      _buildIconBar(isSmall),
                      const Spacer(flex: 2),
                      _buildNameSection(arabicFont, latinFont, isSmall),
                      const Spacer(flex: 2),
                      _buildTargetRow(isSmall),
                      // Buton, üstteki hedef satırı ile alttaki bilgi çipleri
                      // arasında dikeyde tam ortalanır (eşit esnek boşluklar).
                      const Spacer(flex: 3),
                      _buildZikirButton(
                          progress, buttonSize, innerSize, remainFont, isSmall),
                      const Spacer(flex: 3),
                      _buildBottomChips(isSmall),
                      SizedBox(height: isSmall ? 8 : 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: isSmall ? 4 : 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: _p.onBg(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _p.onBg(0.08),
              width: 1,
            ),
          ),
          child: Text(
            '${_currentEsma.index} / ${EsmaData.esmalar.length}',
            style: TextStyle(
              color: _p.onBg(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBar(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.settings_rounded,
            onTap: () => _openScreen(const SettingsScreen()),
          ),
          _buildIconButton(
            icon: Icons.list_rounded,
            onTap: () => _openScreen(const NamesListScreen()),
          ),
          _buildIconButton(
            icon: _isFavorited
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorited ? const Color(0xFFE74C3C) : null,
            onTap: _toggleFavorite,
          ),
          _buildIconButton(
            icon: Icons.history_rounded,
            onTap: () => _openScreen(const HistoryScreen()),
          ),
          _buildIconButton(
            icon: Icons.bookmark_rounded,
            onTap: () => _openScreen(const FavoritesScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _p.onBg(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _p.onBg(0.08),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color ?? _accent,
          size: 20,
        ),
      ),
    );
  }

  /// İsim değişince yöne duyarlı kayma + solma geçişi uygular.
  Widget _slideSwitcher({required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: Offset(0.12 * _navDirection, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: child,
    );
  }

  Widget _buildNameSection(double arabicFont, double latinFont, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16),
      child: Column(
        children: [
          // İsmin çekirdeği (Arapça + Latin + Türkçe) ve iki yanına bitişik
          // gezinme okları. Flexible sayesinde oklar isme yaslanır, kenarlara
          // itilmez.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                semanticLabel: 'Önceki isim',
                onTap: () => _changeEsma(-1),
              ),
              SizedBox(width: isSmall ? 8 : 14),
              Flexible(
                child: _slideSwitcher(
                  child: Column(
                    key: ValueKey('core_$_currentIndex'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentEsma.arapca,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _p.textPrimary,
                          fontSize: arabicFont,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: _accent.withValues(alpha: 0.35),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmall ? 2 : 4),
                      Text(
                        _currentEsma.latin,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _accent,
                          fontSize: latinFont,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: isSmall ? 1 : 2),
                      Text(
                        _currentEsma.turkce,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _p.onBg(0.6),
                          fontSize: isSmall ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 8 : 14),
              _buildNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                semanticLabel: 'Sonraki isim',
                onTap: () => _changeEsma(1),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 4 : 6),
          // Anlam ve fazilet: tam genişlik, dokununca detay sayfası açılır.
          GestureDetector(
            onTap: _showDetailSheet,
            behavior: HitTestBehavior.opaque,
            child: _slideSwitcher(
              child: Column(
                key: ValueKey('desc_$_currentIndex'),
                children: [
                  Text(
                    _currentEsma.anlami,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _p.onBg(0.65),
                      fontSize: isSmall ? 11 : 13,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isSmall ? 3 : 4),
                  Text(
                    _currentEsma.fazilet,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _p.onBg(0.4),
                      fontSize: isSmall ? 10 : 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _p.onBg(0.14),
              _p.onBg(0.03),
            ],
          ),
          border: Border.all(
            color: _accent.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (_vibrationEnabled) {
                VibrationService.vibrateLight();
              }
              onTap();
            },
            customBorder: const CircleBorder(),
            splashColor: _accent.withValues(alpha: 0.25),
            highlightColor: _accent.withValues(alpha: 0.12),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: _accent, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRow(bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTargetChip('Ebced', _currentEsma.ebced, _useEbced, isSmall),
        const SizedBox(width: 8),
        _buildTargetChip('Özel', _customCount, !_useEbced, isSmall),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _confirmReset,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14, vertical: isSmall ? 6 : 8),
            decoration: BoxDecoration(
              color: _p.onBg(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded,
                    color: _p.onBg(0.5), size: isSmall ? 13 : 14),
                const SizedBox(width: 4),
                Text(
                  'Sıfırla',
                  style: TextStyle(
                    color: _p.onBg(0.6),
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _accent, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: _accent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Sıfırla',
              style: TextStyle(
                  color: _p.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '${_currentEsma.latin} zikri baştan başlatılacak. Emin misiniz?',
          style: TextStyle(color: _p.onBg(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal', style: TextStyle(color: _p.onBg(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sıfırla', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _resetCurrentZikir();
    }
  }

  Widget _buildTargetChip(
      String label, int value, bool selected, bool isSmall) {
    return GestureDetector(
      onTap: () {
        final wantEbced = label == 'Ebced';
        _switchTargetMode(wantEbced);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 10 : 14, vertical: isSmall ? 6 : 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_accent, _accentLight],
                )
              : null,
          color: selected ? null : _p.onBg(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _accent : _p.onBg(0.12),
            width: 1,
          ),
        ),
        child: Text(
          '$label · $value',
          style: TextStyle(
            color: selected ? Colors.white : _p.onBg(0.6),
            fontSize: isSmall ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildZikirButton(double progress, double buttonSize,
      double innerSize, double remainingFontSize, bool isSmall) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CircularProgressWidget(
                    progress: progress,
                    size: buttonSize,
                    strokeWidth: buttonSize * 0.073,
                    trackColor: _p.progressTrack,
                    child: Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.25, -0.3),
                          radius: 0.95,
                          colors: _p.buttonGradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _p.buttonGlow.withValues(alpha: 0.45),
                            blurRadius: 44,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: innerSize * 0.8,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$_remaining',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: remainingFontSize,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'kalan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: isSmall ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._ripples.map((r) => Positioned(
                        left: r.position.dx - (buttonSize * 0.34),
                        top: r.position.dy - (buttonSize * 0.34),
                        child: TapGlowEffect(
                          key: ValueKey('glow_${r.id}'),
                          onComplete: () => _removeRipple(r.id),
                          maxRadius: buttonSize * 0.34,
                        ),
                      )),
                  ..._milestones.map((m) => MilestoneFloat(
                        key: ValueKey('milestone_${m.id}'),
                        value: m.value,
                        onComplete: () => _removeMilestone(m.id),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomChips(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInfoChip('Ebced', '${_currentEsma.ebced}', isSmall),
          const SizedBox(width: 8),
          _buildInfoChip('Kalan', '$_remaining', isSmall),
          const SizedBox(width: 8),
          _buildInfoChip('Çekilen', '$_completed', isSmall),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 14, vertical: isSmall ? 6 : 8),
      decoration: BoxDecoration(
        color: _p.onBg(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _p.onBg(0.5),
              fontSize: isSmall ? 10 : 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: _accent,
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _p.dialogBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _p.onBg(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentEsma.arapca,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _p.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentEsma.turkce,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailBlock('Anlamı', _currentEsma.anlami),
                  const SizedBox(height: 14),
                  _buildDetailBlock('Fazileti', _currentEsma.fazilet),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailBlock(String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _p.onBg(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _p.onBg(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _accent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: _p.onBg(0.85),
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleData {
  final int id;
  final Offset position;

  _RippleData({required this.id, required this.position});
}

class _MilestoneData {
  final int id;
  final int value;

  _MilestoneData({required this.id, required this.value});
}
