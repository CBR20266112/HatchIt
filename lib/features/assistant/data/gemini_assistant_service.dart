import 'dart:convert';

import 'package:http/http.dart' as http;

enum AssistantAction { createSchedule, setAlarm, toggleAlarm, chat }

class AssistantScheduleData {
  const AssistantScheduleData({
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
  });

  final String title;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int colorIndex;

  factory AssistantScheduleData.fromJson(Map<String, dynamic> json) {
    return AssistantScheduleData(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : '새 일정',
      dayOfWeek: _toInt(json['day_of_week'], fallback: 1, min: 1, max: 7),
      startTime: _normalizeTime((json['start_time'] as String?) ?? '09:00'),
      endTime: _normalizeTime((json['end_time'] as String?) ?? '10:00'),
      colorIndex: _toInt(json['color_index'], fallback: 0, min: 0, max: 9),
    );
  }
}

class AssistantAlarmData {
  const AssistantAlarmData({
    required this.targetTime,
    required this.isEnabled,
  });

  final String targetTime;
  final bool isEnabled;

  factory AssistantAlarmData.fromJson(Map<String, dynamic> json) {
    return AssistantAlarmData(
      targetTime: _normalizeTime((json['target_time'] as String?) ?? '08:30'),
      isEnabled: _toBool(json['is_enabled'], fallback: true),
    );
  }
}

class AssistantResponse {
  const AssistantResponse({
    required this.action,
    required this.dialogue,
    required this.mascotEmotion,
    required this.scheduleData,
    required this.alarmData,
  });

  final AssistantAction action;
  final String dialogue;
  final String mascotEmotion;
  final AssistantScheduleData? scheduleData;
  final AssistantAlarmData? alarmData;

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    final actionRaw = ((json['action'] as String?) ?? 'CHAT').toUpperCase();
    final action = switch (actionRaw) {
      'CREATE_SCHEDULE' => AssistantAction.createSchedule,
      'SET_ALARM' => AssistantAction.setAlarm,
      'TOGGLE_ALARM' => AssistantAction.toggleAlarm,
      _ => AssistantAction.chat,
    };

    final scheduleJson = json['schedule_data'];
    final alarmJson = json['alarm_data'];

    return AssistantResponse(
      action: action,
      dialogue: ((json['dialogue'] as String?) ?? '알겠어! 반영해볼게.').trim(),
      mascotEmotion: ((json['mascot_emotion'] as String?) ?? 'expr_happy').trim(),
      scheduleData: scheduleJson is Map<String, dynamic>
          ? AssistantScheduleData.fromJson(scheduleJson)
          : null,
      alarmData: alarmJson is Map<String, dynamic>
          ? AssistantAlarmData.fromJson(alarmJson)
          : null,
    );
  }

  factory AssistantResponse.fallback(String dialogue) {
    return AssistantResponse(
      action: AssistantAction.chat,
      dialogue: dialogue,
      mascotEmotion: 'expr_happy',
      scheduleData: null,
      alarmData: null,
    );
  }
}

class GeminiAssistantService {
  const GeminiAssistantService();

  static const String model = 'gemini-1.5-flash';
  static const String apiEndpointBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<AssistantResponse> ask({
    required String userInput,
    required String apiKey,
    required DateTime now,
  }) async {
    final trimmed = userInput.trim();
    if (trimmed.isEmpty) {
      return AssistantResponse.fallback('아직 아무 말도 안 했어!');
    }

    final uri = Uri.parse(
      '$apiEndpointBase/$model:generateContent?key=$apiKey',
    );

    final systemPrompt = '''
너는 대학생 생산성 앱의 고양이 AI 비서다.
반드시 JSON 하나만 응답한다. 마크다운 코드블록 금지.
허용 action: CREATE_SCHEDULE, SET_ALARM, TOGGLE_ALARM, CHAT

규칙:
1) 일정 추가 요청이면 CREATE_SCHEDULE
2) 기상/알람 시간 설정 요청이면 SET_ALARM
3) 알람 켜기/끄기 요청이면 TOGGLE_ALARM
4) 그 외 일반 대화는 CHAT
5) dialogue는 한국어 한 문장, 귀엽고 짧게
6) mascot_emotion은 다음 중 하나 사용: waving, study_burn, alarm_panic, expr_happy, expr_pouty, expr_sad_teary, expr_surprised
7) 시간이 불명확하면 안전한 기본값 사용 (일정 09:00~10:00, 알람 08:30)

반환 스키마:
{
  "action": "CREATE_SCHEDULE" | "SET_ALARM" | "TOGGLE_ALARM" | "CHAT",
  "dialogue": "...",
  "mascot_emotion": "...",
  "schedule_data": {
    "title": "...",
    "day_of_week": 1,
    "start_time": "14:00",
    "end_time": "15:30",
    "color_index": 1
  },
  "alarm_data": {
    "target_time": "08:30",
    "is_enabled": true
  }
}
''';

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  '현재 시각: ${now.toIso8601String()}\n사용자 입력: $trimmed\nJSON만 반환해.'
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.9,
        'responseMimeType': 'application/json',
      },
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini 요청 실패(${response.statusCode}): ${response.body}');
    }

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = root['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return AssistantResponse.fallback('응답을 못 받았어. 다시 말해줘!');
    }

    final first = candidates.first;
    if (first is! Map<String, dynamic>) {
      return AssistantResponse.fallback('응답 형식이 이상해. 다시 시도해줘!');
    }

    final content = first['content'];
    if (content is! Map<String, dynamic>) {
      return AssistantResponse.fallback('내용이 비어 있어. 다시 말해줘!');
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return AssistantResponse.fallback('응답 텍스트가 없네. 다시 해볼까?');
    }

    final text = ((parts.first as Map<String, dynamic>)['text'] as String?) ?? '';
    final normalized = _extractJsonObject(text);
    final decoded = jsonDecode(normalized);
    if (decoded is! Map<String, dynamic>) {
      return AssistantResponse.fallback('JSON 파싱이 실패했어. 다시 해보자!');
    }

    return AssistantResponse.fromJson(decoded);
  }
}

String _extractJsonObject(String raw) {
  final trimmed = raw.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    return trimmed;
  }
  return trimmed.substring(start, end + 1);
}

int _toInt(dynamic value, {required int fallback, int? min, int? max}) {
  int parsed;
  if (value is int) {
    parsed = value;
  } else if (value is String) {
    parsed = int.tryParse(value) ?? fallback;
  } else {
    parsed = fallback;
  }

  if (min != null && parsed < min) {
    parsed = min;
  }
  if (max != null && parsed > max) {
    parsed = max;
  }
  return parsed;
}

bool _toBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return fallback;
}

String _normalizeTime(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) {
    return '08:30';
  }
  var hh = int.tryParse(match.group(1)!) ?? 8;
  var mm = int.tryParse(match.group(2)!) ?? 30;
  if (hh < 0) {
    hh = 0;
  }
  if (hh > 23) {
    hh = 23;
  }
  if (mm < 0) {
    mm = 0;
  }
  if (mm > 59) {
    mm = 59;
  }
  return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}
