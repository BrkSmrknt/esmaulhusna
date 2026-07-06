import 'package:flutter/material.dart';
import '../data/esma_data.dart';
import '../models/esma_model.dart';
import '../services/storage_service.dart';
import '../services/vibration_service.dart';
import '../widgets/circular_progress.dart';
import '../widgets/ripple_effect.dart';
import '../widgets/milestone_float.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ZikirScreen extends StatefulWidget {
  final int initialIndex;

  const ZikirScreen({super.key, this.initialIndex = 0});

  @override
  State<ZikirScreen> createState() => _ZikirScreenState();
}

class _ZikirScreenState extends State<ZikirScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late int _remaining;
  bool _isFavorited = false;
  bool _vibrationEnabled = true;
  int _customCount = 33;
  bool _useEbced = true;
  final List<_RippleData> _ripples = [];
  final List<_MilestoneData> _milestones = [];
  int _effectSeq = 0;

  /// Kilometre taşı animasyonunun tetikleneceği ilerleme oranları (% olarak).
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

    _loadSettings();
    _loadSavedCount();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _vibrationEnabled = await StorageService.getVibrationEnabled();
    _isFavorited = await StorageService.isFavorite(_currentIndex);
    _customCount = await StorageService.getCustomCount();
    if (!_useEbced) {
      _remaining = _totalCount;
    }
    setState(() {});
  }

  Future<void> _loadSavedCount() async {
    final history = await StorageService.getHistory();
    final existing = history.where((h) => h.esmaIndex == _currentIndex);
    if (existing.isNotEmpty) {
      final entry = existing.first;
      if (!entry.isCompleted) {
        setState(() {
          _remaining = entry.targetCount - entry.completedCount;
        });
      }
    }
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

      // Her %10 ilerlemede kalan sayıyı büyükçe yukarı süzdür.
      if (total > 0 &&
          _remaining > 0 &&
          _crossedMilestone(oldCompleted, _completed, total)) {
        _milestones.add(_MilestoneData(id: _effectSeq++, value: _remaining));
      }
    });

    StorageService.updateZikirCount(
      _currentIndex,
      _currentEsma.latin,
      _totalCount,
      _completed,
    );

    if (_remaining <= 0) {
      StorageService.incrementCompletion(
        _currentIndex,
        _currentEsma.latin,
        _totalCount,
      );
      _showCompletionDialog();
    }
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF6B35), width: 2),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFF6B35), size: 28),
            SizedBox(width: 8),
            Text(
              'MashaAllah!',
              style: TextStyle(
                color: Colors.white,
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
                color: Color(0xFFFF6B35),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_totalCount defa tamamlandı!',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                },
                child: const Text('Tekrarla',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _nextEsma();
                },
                child: const Text('Sonraki İsim',
                    style: TextStyle(color: Color(0xFFFF6B35))),
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

  void _previousEsma() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + EsmaData.esmalar.length) %
          EsmaData.esmalar.length;
      _remaining = _totalCount;
    });
    _loadSavedCount();
    _loadSettings();
  }

  void _nextEsma() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % EsmaData.esmalar.length;
      _remaining = _totalCount;
    });
    _loadSavedCount();
    _loadSettings();
  }

  void _toggleFavorite() async {
    await StorageService.toggleFavorite(_currentIndex);
    _isFavorited = !_isFavorited;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalCount > 0 ? _completed / _totalCount : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  _buildIconBar(),
                  Expanded(
                    child: _buildMainContent(progress),
                  ),
                ],
              ),
              _buildSideNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            '${_currentEsma.index} / ${EsmaData.esmalar.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNav() {
    final prevIndex =
        (_currentIndex - 1 + EsmaData.esmalar.length) % EsmaData.esmalar.length;
    final nextIndex = (_currentIndex + 1) % EsmaData.esmalar.length;

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavArrow(
              icon: Icons.chevron_left_rounded,
              label: EsmaData.esmalar[prevIndex].latin,
              onTap: _previousEsma,
              alignLeft: true,
            ),
            _buildNavArrow(
              icon: Icons.chevron_right_rounded,
              label: EsmaData.esmalar[nextIndex].latin,
              onTap: _nextEsma,
              alignLeft: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool alignLeft,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: alignLeft ? 8 : 0,
          right: alignLeft ? 0 : 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFFFF6B35), size: 30),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 76,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            icon: Icons.settings_rounded,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadSettings();
            },
          ),
          _buildIconButton(
            icon: _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isFavorited ? const Color(0xFFE74C3C) : null,
            onTap: _toggleFavorite,
          ),
          _buildIconButton(
            icon: Icons.history_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          _buildIconButton(
            icon: Icons.bookmark_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color ?? const Color(0xFFFF6B35),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMainContent(double progress) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Arabic name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _currentEsma.arapca,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                height: 1.35,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Latin name
          Text(
            _currentEsma.latin,
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          // Turkish name
          Text(
            _currentEsma.turkce,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Meaning
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Text(
                _currentEsma.anlami,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fazilet (dokununca tam metin açılır)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GestureDetector(
              onTap: _showDetailSheet,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    _currentEsma.fazilet,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Devamını oku',
                        style: TextStyle(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.expand_more_rounded,
                          color: Color(0xFFFF6B35), size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Hedef seçici: Ebced / Özel
          _buildTargetSelector(),
          const SizedBox(height: 24),
          // Zikir Button
          _buildZikirButton(progress),
          const SizedBox(height: 20),
          // Ebced info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip('Ebced', '${_currentEsma.ebced}'),
              const SizedBox(width: 12),
              _buildInfoChip('Kalan', '$_remaining'),
              const SizedBox(width: 12),
              _buildInfoChip('Çekilen', '$_completed'),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTargetChip('Ebced', _currentEsma.ebced, _useEbced),
        const SizedBox(width: 10),
        _buildTargetChip('Özel', _customCount, !_useEbced),
      ],
    );
  }

  Widget _buildTargetChip(String label, int value, bool selected) {
    return GestureDetector(
      onTap: () {
        final wantEbced = label == 'Ebced';
        if (wantEbced == _useEbced) return;
        setState(() {
          _useEbced = wantEbced;
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
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF6B35)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Text(
          '$label · $value',
          style: TextStyle(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showDetailSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentEsma.arapca,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentEsma.turkce,
                    style: const TextStyle(
                      color: Color(0xFFFF6B35),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZikirButton(double progress) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressWidget(
                    progress: progress,
                    size: 300,
                    strokeWidth: 22,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.25, -0.3),
                          radius: 0.95,
                          colors: [
                            Color(0xFF2E7D63),
                            Color(0xFF1B5E4F),
                            Color(0xFF0C3A30),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D63).withValues(alpha: 0.45),
                            blurRadius: 44,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'kalan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._ripples.map((r) => Positioned(
                        left: r.position.dx - 95,
                        top: r.position.dy - 95,
                        child: RippleEffect(
                          key: ValueKey('ripple_${r.id}'),
                          onComplete: () => _removeRipple(r.id),
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
