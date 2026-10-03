import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../mascot/domain/mascot_species.dart';

enum AssistantAction { createSchedule, setAlarm, toggleAlarm, chat }

class AssistantScheduleData {
  const AssistantScheduleData({
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
    this.date, // 'YYYY-MM-DD' 단발성 일정, null이면 주간 반복
  });

  final String title;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int colorIndex;
  final String? date;

  factory AssistantScheduleData.fromJson(Map<String, dynamic> json) {
    return AssistantScheduleData(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : '새 일정',
      dayOfWeek: _toInt(json['day_of_week'], fallback: 1, min: 1, max: 7),
      startTime: _normalizeTime((json['start_time'] as String?) ?? '09:00'),
      endTime: _normalizeTime((json['end_time'] as String?) ?? '10:00'),
      colorIndex: _toInt(json['color_index'], fallback: 0, min: 0, max: 9),
      date: (json['date'] as String?)?.trim().isEmpty == true
          ? null
          : json['date'] as String?,
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
      'CREATE_SCHEDULE' || 'ADD_TIMETABLE' => AssistantAction.createSchedule,
      'SET_ALARM' => AssistantAction.setAlarm,
      'TOGGLE_ALARM' => AssistantAction.toggleAlarm,
      _ => AssistantAction.chat,
    };

    // 평면 구조(root) 또는 중첩 구조(schedule_data) 모두 지원
    final scheduleJson = json['schedule_data'] is Map<String, dynamic>
        ? json['schedule_data'] as Map<String, dynamic>
        : (json['title'] != null ? json : null);

    final alarmJson = json['alarm_data'];

    final dialogue = ((json['dialogue'] as String?) ??
            (json['reply_message'] as String?) ??
            '알겠어! 반영해볼게.')
        .trim();

    return AssistantResponse(
      action: action,
      dialogue: dialogue,
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
  static const String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<AssistantResponse> ask({
    required String userInput,
    required String apiKey,
    required DateTime now,
    int? speciesId,
  }) async {
    final cleanApiKey = apiKey.trim();
    if (cleanApiKey.isEmpty) {
      throw Exception('Gemini API 키가 설정되지 않았습니다. 설정에서 API 키를 입력해주세요.');
    }

    final trimmed = userInput.trim();
    if (trimmed.isEmpty) {
      return AssistantResponse.fallback('아직 아무 말도 안 했어!');
    }

    final species = MascotSpeciesDefinition.byId(speciesId ?? 1);
    final uri = Uri.parse(apiEndpoint);

    final systemPrompt = '''
너는 대학생 생산성 앱의 AI 비서 마스코트 '${species.name}'이다.
성격 및 페르소나: ${species.persona}
말투 특징: 반드시 말끝마다 '${species.signatureSuffix}'를 자연스럽게 붙여라.

반드시 JSON 하나만 응답한다. 마크다운 코드블록 금지.
허용 action: CREATE_SCHEDULE, SET_ALARM, TOGGLE_ALARM, CHAT

규칙:
1) 수업, 과제, 시험뿐만 아니라 모임, 회의, 스터디, 식사 약속, 동아리, 운동 등 모든 일상 일정 추가 요청이면 action을 CREATE_SCHEDULE로 설정하라.
2) 기상/알람 시간 설정 요청이면 SET_ALARM
3) 알람 켜기/끄기 요청이면 TOGGLE_ALARM
4) 그 외 일반 대화는 CHAT
5) dialogue는 한국어 한 문장, 너의 고유 말투('${species.signatureSuffix}')를 살려 귀엽고 친절하게 작성하라.
6) mascot_emotion은 다음 중 하나 사용: waving, study_burn, alarm_panic, expr_happy, expr_pouty, expr_sad_teary, expr_surprised
7) day_of_week는 1(월요일), 2(화요일), 3(수요일), 4(목요일), 5(금요일), 6(토요일), 7(일요일)로 지정
8) 시간(start_time, end_time, target_time)은 반드시 24시간 형식 "HH:mm"으로 지정
9) 종료 시간(end_time)에 대한 언급이 없으면 start_time 기준 기본 1시간 뒤로 설정하라.
10) 시간이 불명확하면 안전한 기본값 사용 (일정 09:00~10:00, 알람 08:30)
11) date 필드:
    - 사용자가 특정 날짜를 지정한 경우("5일", "오늘", "내일", "수요일에" 등 1회성 약속)는 "YYYY-MM-DD" 형식으로 date를 반드시 설정하라.
    - 순수 반복 수업(매주 반복)은 date를 null로 설정하라.

반환 스키마:
{
  "action": "CREATE_SCHEDULE" | "SET_ALARM" | "TOGGLE_ALARM" | "CHAT",
  "title": "사용자가 말한 일정 내용 (예: 동아리 회의, 점심 약속)",
  "day_of_week": 1,
  "start_time": "14:00",
  "end_time": "15:00",
  "date": "2024-10-15",
  "dialogue": "...",
  "mascot_emotion": "expr_happy",
  "schedule_data": {
    "title": "사용자가 말한 일정 내용",
    "day_of_week": 1,
    "start_time": "14:00",
    "end_time": "15:00",
    "color_index": 1,
    "date": "2024-10-15"
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

    final cleanKey = apiKey.trim();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (cleanKey.startsWith('AQ.') || cleanKey.startsWith('ya29.')) {
      headers['Authorization'] = 'Bearer $cleanKey';
    } else {
      headers['x-goog-api-key'] = cleanKey;
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[Gemini API Error] HTTP ${response.statusCode}: ${response.body}');
      if (response.body.contains('API_KEY_SERVICE_BLOCKED') ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        throw Exception('API_KEY_SERVICE_BLOCKED');
      }
      throw Exception('HTTP ${response.statusCode}');
    }

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = root['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      debugPrint('[Gemini API Error] candidates 비어있음: ${response.body}');
      throw Exception('응답 후보(candidates)가 없습니다: ${response.body}');
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

/// 오프라인 로컬 규칙 파서 (API 키 부재 시 또는 오프라인 폴백용)
class LocalScheduleParser {
  const LocalScheduleParser._();

  static AssistantResponse parse(String input, {DateTime? now, int? speciesId}) {
    final current = now ?? DateTime.now();
    final trimmed = input.trim();
    final species = MascotSpeciesDefinition.byId(speciesId ?? 1);

    // 1. 날짜 추출 (dayOfWeek: 1=월, 7=일)
    int dayOfWeek = current.weekday; // 기본값: 오늘 요일

    if (trimmed.contains('내일')) {
      dayOfWeek = (current.weekday % 7) + 1;
    } else if (trimmed.contains('모레')) {
      dayOfWeek = ((current.weekday + 1) % 7) + 1;
    } else if (trimmed.contains('글피')) {
      dayOfWeek = ((current.weekday + 2) % 7) + 1;
    } else if (RegExp(r'월요일|월욜|월').hasMatch(trimmed)) {
      dayOfWeek = 1;
    } else if (RegExp(r'화요일|화욜|화').hasMatch(trimmed)) {
      dayOfWeek = 2;
    } else if (RegExp(r'수요일|수욜|수').hasMatch(trimmed)) {
      dayOfWeek = 3;
    } else if (RegExp(r'목요일|목욜|목').hasMatch(trimmed)) {
      dayOfWeek = 4;
    } else if (RegExp(r'금요일|금욜|금').hasMatch(trimmed)) {
      dayOfWeek = 5;
    } else if (RegExp(r'토요일|토욜|토').hasMatch(trimmed)) {
      dayOfWeek = 6;
    } else if (RegExp(r'일요일|일욜|일').hasMatch(trimmed)) {
      dayOfWeek = 7;
    }

    // 2. 시간 추출
    int startHour = 9;
    int startMinute = 0;
    final isPm = trimmed.contains('오후') || trimmed.contains('저녁') || trimmed.contains('밤');
    final isAm = trimmed.contains('오전') || trimmed.contains('새벽') || trimmed.contains('아침');

    if (trimmed.contains('점심')) {
      startHour = 12;
      startMinute = 0;
    } else if (trimmed.contains('저녁') && !RegExp(r'\d+\s*시').hasMatch(trimmed)) {
      startHour = 18;
      startMinute = 0;
    }

    final timeRegex = RegExp(r'(\d{1,2})\s*[:시]\s*(\d{1,2})?\s*분?\s*(?:에|까지|부터|에는|쯤|경|이전|이후)?');
    final match = timeRegex.firstMatch(trimmed);
    if (match != null) {
      var parsedHour = int.parse(match.group(1)!);
      final parsedMinute = match.group(2) != null ? int.parse(match.group(2)!) : 0;

      if (isPm && parsedHour < 12) {
        parsedHour += 12;
      } else if (isAm && parsedHour == 12) {
        parsedHour = 0;
      }
      startHour = parsedHour.clamp(0, 23);
      startMinute = parsedMinute.clamp(0, 59);
    }

    // 3. 종료 시간 (기본 1시간 뒤)
    final endHour = (startHour + 1) % 24;
    final endMinute = startMinute;

    final startTimeStr = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

    // 4. 제목 추출: 날짜/시간/서술어 제외한 나머지 문구
    var title = trimmed;
    title = title.replaceAll(RegExp(r'오늘|내일|모레|글피|[월화수목금토일]요일?'), ' ');
    title = title.replaceAll(RegExp(r'(오전|오후|저녁|새벽|아침|밤)'), ' ');
    title = title.replaceAll(RegExp(r'\b(까지|부터|에는|쯤|경|이전|이후)\b'), ' ');
    title = title.replaceAll(timeRegex, ' ');
    title = title.replaceAll(
      RegExp(r'등록해줘|추가해줘|잡아줘|넣어줘|만들어줘|해줘|할래|있어|일정|시간표|스케줄|약속'),
      ' ',
    );
    title = title.replaceAll(RegExp(r'[!?,.~]'), ' ').trim();

    // 앞머리에 남은 불필요한 조사 일괄 제거
    title = title.replaceFirst(
      RegExp(r'^(까지|부터|에|에는|으로|로|은|는|이|가|\s)+'),
      '',
    ).trim();

    // 문장 앞머리 감탄사/추임새 제거 ("야", "어이", "저기", "있잖아", "음", "아" 등)
    title = title.replaceFirst(
      RegExp(r'^(야|어이|저기|있잖아|음|아|어|이봐|잠깐|\s)+'),
      '',
    ).trim();

    if (title.isEmpty) {
      title = '새 일정';
    }

    const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final dayStr = dayNames[dayOfWeek];

    // dayOfWeek 기준으로 실제 날짜 계산 (오늘부터 가장 가까운 해당 요일)
    int daysAhead = dayOfWeek - current.weekday;
    if (daysAhead < 0) daysAhead += 7;
    final targetDate = current.add(Duration(days: daysAhead));
    final dateStr = '${targetDate.year.toString().padLeft(4, '0')}-'
        '${targetDate.month.toString().padLeft(2, '0')}-'
        '${targetDate.day.toString().padLeft(2, '0')}';

    return AssistantResponse(
      action: AssistantAction.createSchedule,
      dialogue: '$dayStr요일 $startTimeStr에 "$title" 일정을 등록했어${species.signatureSuffix}!',
      mascotEmotion: 'expr_happy',
      scheduleData: AssistantScheduleData(
        title: title,
        dayOfWeek: dayOfWeek,
        startTime: startTimeStr,
        endTime: endTimeStr,
        colorIndex: 1,
        date: dateStr,
      ),
      alarmData: null,
    );
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
