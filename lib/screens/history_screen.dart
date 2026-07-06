import 'package:flutter/material.dart';
import '../models/zikir_history.dart';
import '../services/storage_service.dart';
import 'zikir_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ZikirHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _history = await StorageService.getHistory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Color(0xFFFF6B35),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Zikir Geçmişi',
            style: TextStyle(
              color: Colors.white,
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
            Icons.history_rounded,
            color: Colors.white.withValues(alpha: 0.15),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz zikir geçmişi yok',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zikir çekmeye başladığınızda\ngeçmişiniz burada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 14,
            ),
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

        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ZikirScreen(initialIndex: item.esmaIndex),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isCompleted
                    ? const Color(0xFF27AE60).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Progress circle
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.isCompleted
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFFF6B35),
                        ),
                      ),
                      item.isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFF27AE60), size: 22)
                          : Text(
                              '$remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.latin,
                        style: const TextStyle(
                          color: Colors.white,
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
                          color: item.isCompleted
                              ? const Color(0xFF27AE60)
                              : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      if (item.completionCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Toplam ${item.completionCount} kez tamamlandı',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.completionCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF27AE60), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${item.completionCount}×',
                          style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
