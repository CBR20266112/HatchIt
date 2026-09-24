enum DailySlotType { morning, evening }

class DailyRecord {
  const DailyRecord({
    this.id,
    required this.recordDate,
    required this.slotType,
    required this.moodLevel,
    required this.questionText,
    required this.userAnswer,
    required this.createdAt,
  });

  final int? id;
  final String recordDate;
  final DailySlotType slotType;
  final int moodLevel;
  final String questionText;
  final String userAnswer;
  final DateTime createdAt;

  DailyRecord copyWith({
    int? id,
    String? recordDate,
    DailySlotType? slotType,
    int? moodLevel,
    String? questionText,
    String? userAnswer,
    DateTime? createdAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      recordDate: recordDate ?? this.recordDate,
      slotType: slotType ?? this.slotType,
      moodLevel: moodLevel ?? this.moodLevel,
      questionText: questionText ?? this.questionText,
      userAnswer: userAnswer ?? this.userAnswer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'record_date': recordDate,
      'slot_type': _slotTypeToDb(slotType),
      'mood_level': moodLevel,
      'question_text': questionText,
      'user_answer': userAnswer,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyRecord.fromMap(Map<String, Object?> map) {
    return DailyRecord(
      id: map['id'] as int?,
      recordDate: (map['record_date'] as String?) ?? '',
      slotType: _slotTypeFromDb((map['slot_type'] as String?) ?? 'MORNING'),
      moodLevel: (map['mood_level'] as int?) ?? 3,
      questionText: (map['question_text'] as String?) ?? '',
      userAnswer: (map['user_answer'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  static String _slotTypeToDb(DailySlotType type) {
    switch (type) {
      case DailySlotType.morning:
        return 'MORNING';
      case DailySlotType.evening:
        return 'EVENING';
    }
  }

  static DailySlotType _slotTypeFromDb(String value) {
    switch (value) {
      case 'EVENING':
        return DailySlotType.evening;
      case 'MORNING':
      default:
        return DailySlotType.morning;
    }
  }
}
