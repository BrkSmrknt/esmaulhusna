class ZikirHistory {
  final int esmaIndex;
  final String latin;
  final int targetCount;
  final int completedCount;
  final DateTime lastDate;
  final bool isCompleted;

  /// Bu ismin şimdiye kadar kaç kez baştan sona tamamlandığı.
  final int completionCount;

  const ZikirHistory({
    required this.esmaIndex,
    required this.latin,
    required this.targetCount,
    required this.completedCount,
    required this.lastDate,
    required this.isCompleted,
    this.completionCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'esmaIndex': esmaIndex,
      'latin': latin,
      'targetCount': targetCount,
      'completedCount': completedCount,
      'lastDate': lastDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completionCount': completionCount,
    };
  }

  factory ZikirHistory.fromMap(Map<String, dynamic> map) {
    return ZikirHistory(
      esmaIndex: map['esmaIndex'] as int,
      latin: map['latin'] as String,
      targetCount: map['targetCount'] as int,
      completedCount: map['completedCount'] as int,
      lastDate: DateTime.parse(map['lastDate'] as String),
      isCompleted: map['isCompleted'] as bool,
      completionCount: map['completionCount'] as int? ?? 0,
    );
  }

  ZikirHistory copyWith({
    int? esmaIndex,
    String? latin,
    int? targetCount,
    int? completedCount,
    DateTime? lastDate,
    bool? isCompleted,
    int? completionCount,
  }) {
    return ZikirHistory(
      esmaIndex: esmaIndex ?? this.esmaIndex,
      latin: latin ?? this.latin,
      targetCount: targetCount ?? this.targetCount,
      completedCount: completedCount ?? this.completedCount,
      lastDate: lastDate ?? this.lastDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completionCount: completionCount ?? this.completionCount,
    );
  }
}
