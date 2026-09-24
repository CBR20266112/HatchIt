enum ScheduleType { classType, event }

class Schedule {
  const Schedule({
    this.id,
    required this.title,
    required this.type,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.isCompleted,
    required this.alarmOffsetMinutes,
  });

  final int? id;
  final String title;
  final ScheduleType type;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? location;
  final bool isCompleted;
  final int alarmOffsetMinutes;

  Schedule copyWith({
    int? id,
    String? title,
    ScheduleType? type,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? location,
    bool? isCompleted,
    int? alarmOffsetMinutes,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      alarmOffsetMinutes: alarmOffsetMinutes ?? this.alarmOffsetMinutes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'type': _typeToDb(type),
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'is_completed': isCompleted ? 1 : 0,
      'alarm_offset_minutes': alarmOffsetMinutes,
    };
  }

  factory Schedule.fromMap(Map<String, Object?> map) {
    return Schedule(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      type: _typeFromDb((map['type'] as String?) ?? 'CLASS'),
      dayOfWeek: (map['day_of_week'] as int?) ?? 1,
      startTime: (map['start_time'] as String?) ?? '09:00',
      endTime: (map['end_time'] as String?) ?? '10:00',
      location: map['location'] as String?,
      isCompleted: ((map['is_completed'] as int?) ?? 0) == 1,
      alarmOffsetMinutes: (map['alarm_offset_minutes'] as int?) ?? 30,
    );
  }

  static String _typeToDb(ScheduleType type) {
    switch (type) {
      case ScheduleType.classType:
        return 'CLASS';
      case ScheduleType.event:
        return 'EVENT';
    }
  }

  static ScheduleType _typeFromDb(String value) {
    switch (value) {
      case 'EVENT':
        return ScheduleType.event;
      case 'CLASS':
      default:
        return ScheduleType.classType;
    }
  }
}
