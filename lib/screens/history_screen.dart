import 'package:flutter/material.dart';
import '../models/zikir_history.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _danger = Color(0xFFE74C3C);
  static const Color _success = Color(0xFF27AE60);

  AppPalette _p = AppPalette.dark;

  List<ZikirHistory> _history = [];
  final Set<int> _selectedIndices = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _history = await StorageService.getHistory();
    setState(() {});
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _selectionMode = false;
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIndices.length == _history.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(_history.length, (i) => i));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIndices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _danger, width: 2),
        ),
        title: Text(
          'Silme Onayı',
          style:
              TextStyle(color: _p.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${_selectedIndices.length} zikir geçmişi silinecek. Emin misiniz?',
          style: TextStyle(color: _p.onBg(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal', style: TextStyle(color: _p.onBg(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final indicesToRemove =
        _selectedIndices.map((i) => _history[i].esmaIndex).toList();

    for (final esmaIndex in indicesToRemove) {
      await StorageService.removeHistoryEntry(esmaIndex);
    }

    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });
    await _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${indicesToRemove.length} zikir silindi'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
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
                child: _history.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
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
            onTap: () {
              if (_selectionMode) {
                setState(() {
                  _selectionMode = false;
                  _selectedIndices.clear();
                });
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _p.onBg(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _selectionMode
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_rounded,
                color: _accent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _selectionMode
                  ? '${_selectedIndices.length} seçili'
                  : 'Zikir Geçmişi',
              style: TextStyle(
                color: _p.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_selectionMode) ...[
            GestureDetector(
              onTap: _selectAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _p.onBg(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _p.onBg(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  _selectedIndices.length == _history.length
                      ? 'Hiçbirini Seçme'
                      : 'Tümünü Seç',
                  style: TextStyle(
                    color: _p.onBg(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _deleteSelected,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _danger.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: _danger,
                  size: 20,
                ),
              ),
            ),
          ],
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
            Icons.history_rounded,
            color: _p.onBg(0.15),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz zikir geçmişi yok',
            style: TextStyle(color: _p.onBg(0.4), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Zikir çekmeye başladığınızda\ngeçmişiniz burada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(color: _p.onBg(0.25), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final remaining = item.targetCount - item.completedCount;
        final progress = item.targetCount > 0
            ? item.completedCount / item.targetCount
            : 0.0;
        final isSelected = _selectedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
              _toggleSelection(index);
            } else {
              Navigator.pop(context, item.esmaIndex);
            }
          },
          onLongPress: () {
            if (!_selectionMode) {
              setState(() => _selectionMode = true);
            }
            _toggleSelection(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? _danger.withValues(alpha: 0.12)
                  : _p.onBg(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _danger.withValues(alpha: 0.5)
                    : item.isCompleted
                        ? _success.withValues(alpha: 0.5)
                        : _p.onBg(0.08),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (_selectionMode) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _danger : _p.onBg(0.08),
                      border: Border.all(
                        color: isSelected ? _danger : _p.onBg(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                ],
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: _p.onBg(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.isCompleted ? _success : _accent,
                        ),
                      ),
                      item.isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: _success, size: 22)
                          : Text(
                              '$remaining',
                              style: TextStyle(
                                color: _p.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.latin,
                        style: TextStyle(
                          color: _p.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.isCompleted
                            ? 'Tamamlandı'
                            : '$remaining / ${item.targetCount} kaldı',
                        style: TextStyle(
                          color: item.isCompleted ? _success : _p.onBg(0.55),
                          fontSize: 13,
                        ),
                      ),
                      if (item.completionCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Toplam ${item.completionCount} kez tamamlandı',
                          style: TextStyle(
                            color: _p.onBg(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.completionCount > 0 && !_selectionMode) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _success.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: _success, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${item.completionCount}×',
                          style: const TextStyle(
                            color: _success,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_selectionMode) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _p.onBg(0.3),
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
