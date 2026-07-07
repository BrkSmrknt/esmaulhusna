import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _accentLight = Color(0xFFFF8E53);

  AppPalette _p = AppPalette.dark;

  bool _vibrationEnabled = true;
  int _customCount = 33;
  final TextEditingController _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _vibrationEnabled = await StorageService.getVibrationEnabled();
    _customCount = await StorageService.getCustomCount();
    _countController.text = _customCount.toString();
    setState(() {});
  }

  void _saveCustomCount() {
    final count = int.tryParse(_countController.text);
    if (count != null && count > 0) {
      setState(() {
        _customCount = count;
      });
      StorageService.setCustomCount(count);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zikir sayısı $count olarak ayarlandı.'),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _p = ThemeScope.of(context);
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildThemeToggle(),
                      const SizedBox(height: 16),
                      _buildVibrationToggle(),
                      const SizedBox(height: 16),
                      _buildCustomCountSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _p.onBg(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: _accent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Ayarlar',
            style: TextStyle(
              color: _p.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _p.onBg(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _p.onBg(0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildRowIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _accent, size: 24),
    );
  }

  Widget _buildLabelColumn(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _p.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: _p.onBg(0.55), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    final isLight = !_p.isDark;
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildRowIcon(
                  isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              const SizedBox(width: 16),
              _buildLabelColumn(
                'Aydınlık Mod',
                isLight ? 'Renkli açık tema' : 'Koyu tema etkin',
              ),
            ],
          ),
          Switch(
            value: isLight,
            onChanged: (value) => appTheme.setDark(!value),
            activeThumbColor: _accent,
            activeTrackColor: _accent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationToggle() {
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildRowIcon(Icons.vibration_rounded),
              const SizedBox(width: 16),
              _buildLabelColumn('Titreşim', 'Dokunuşlarda titreşim'),
            ],
          ),
          Switch(
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
              StorageService.setVibrationEnabled(value);
            },
            activeThumbColor: _accent,
            activeTrackColor: _accent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCountSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRowIcon(Icons.tag_rounded),
              const SizedBox(width: 16),
              _buildLabelColumn(
                  'Özel Zikir Sayısı', 'Hedef zikir sayısını belirleyin'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _p.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Sayı girin',
                    hintStyle: TextStyle(color: _p.onBg(0.25)),
                    filled: true,
                    fillColor: _p.onBg(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _p.onBg(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _p.onBg(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _saveCustomCount,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accent, _accentLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Hızlı Seçim',
            style: TextStyle(
              color: _p.onBg(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [33, 99, 100, 500, 1000].map((count) {
              final isSelected = _customCount == count;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _customCount = count;
                    _countController.text = count.toString();
                  });
                  StorageService.setCustomCount(count);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [_accent, _accentLight],
                          )
                        : null,
                    color: isSelected ? null : _p.onBg(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _accent : _p.onBg(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : _p.onBg(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
