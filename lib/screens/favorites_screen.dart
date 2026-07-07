import 'package:flutter/material.dart';
import '../data/esma_data.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _danger = Color(0xFFE74C3C);

  AppPalette _p = AppPalette.dark;

  List<int> _favoriteIndices = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _favoriteIndices = await StorageService.getFavorites();
    setState(() {});
  }

  Future<void> _removeFavorite(int esmaIndex) async {
    await StorageService.toggleFavorite(esmaIndex);
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kısayol kaldırıldı'),
          backgroundColor: const Color(0xFF16213E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
                child: _favoriteIndices.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(),
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
            'Favoriler',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: _p.onBg(0.15),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz favori eklenmemiş',
            style: TextStyle(color: _p.onBg(0.4), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Kalp ikonuna tıklayarak\nfavorilerinize ekleyebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(color: _p.onBg(0.25), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _favoriteIndices.length,
      itemBuilder: (context, index) {
        final esmaIndex = _favoriteIndices[index];
        if (esmaIndex >= EsmaData.esmalar.length) {
          return const SizedBox.shrink();
        }
        final esma = EsmaData.esmalar[esmaIndex];

        return GestureDetector(
          onTap: () => Navigator.pop(context, esmaIndex),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _p.onBg(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _danger.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_danger, Color(0xFFC0392B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _danger.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${esma.index}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esma.latin,
                        style: TextStyle(
                          color: _p.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esma.anlami,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _p.onBg(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeFavorite(esmaIndex),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: _danger,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
