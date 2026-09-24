import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/schedule.dart';
import 'schedule_dao.dart';

class TimetableOcrService {
  TimetableOcrService(this._scheduleDao);

  final ScheduleDao _scheduleDao;

  Future<List<Schedule>> parseTimetableImage(File imageFile, String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('Gemini API key is empty');
    }
    if (!await imageFile.exists()) {
      throw ArgumentError('Image file does not exist: ${imageFile.path}');
    }

    final imageBytes = await imageFile.readAsBytes();
    final encoded = base64Encode(imageBytes);

    const prompt = '''
당신은 시간표 OCR 파서입니다.
이미지에서 강의/일정 정보를 추출해 아래 JSON만 반환하세요.
설명문/코드블록/마크다운 없이 JSON 본문만 출력합니다.

스키마:
{
  "schedules": [
    {
      "title": "문자열",
      "type": "CLASS 또는 EVENT",
      "day_of_week": 1,
      "start_time": "HH:mm",
      "end_time": "HH:mm",
      "location": "문자열 또는 빈문자열",
      "alarm_offset_minutes": 30
    }
  ]
}

규칙:
- day_of_week: 월=1 ... 일=7
- alarm_offset_minutes: 30, 60, 90, 120 중 하나
- 값이 불명확하면 해당 항목은 제외
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': encoded,
                }
              },
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractText(decoded);
    final jsonText = _extractJsonText(text);
    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;

    final rawSchedules = (parsed['schedules'] as List<dynamic>? ?? const []);
    final schedules = rawSchedules
        .map((raw) => _mapToSchedule(raw as Map<String, dynamic>))
        .whereType<Schedule>()
        .toList();

    if (schedules.isEmpty) {
      return const [];
    }

    return _scheduleDao.batchInsert(schedules);
  }

  String _extractText(Map<String, dynamic> payload) {
    final candidates = payload['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini response has no candidates');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final part = parts?.first as Map<String, dynamic>?;
    final text = part?['text'] as String?;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini response text is empty');
    }

    return text;
  }

  String _extractJsonText(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final match = fence.firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.trim();
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return trimmed.substring(start, end + 1);
    }

    throw Exception('No valid JSON object found in Gemini response');
  }

  Schedule? _mapToSchedule(Map<String, dynamic> map) {
    final title = (map['title'] as String?)?.trim();
    final typeRaw = (map['type'] as String?)?.trim().toUpperCase();
    final dayOfWeek = map['day_of_week'] as int?;
    final startTime = (map['start_time'] as String?)?.trim();
    final endTime = (map['end_time'] as String?)?.trim();
    final location = (map['location'] as String?)?.trim();
    final offset = (map['alarm_offset_minutes'] as int?) ?? 30;

    if (title == null || title.isEmpty) {
      return null;
    }
    if (dayOfWeek == null || dayOfWeek < 1 || dayOfWeek > 7) {
      return null;
    }
    if (startTime == null || endTime == null) {
      return null;
    }
    if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
      return null;
    }

    final normalizedOffset = <int>[30, 60, 90, 120].contains(offset) ? offset : 30;

    return Schedule(
      title: title,
      type: typeRaw == 'EVENT' ? ScheduleType.event : ScheduleType.classType,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: (location == null || location.isEmpty) ? null : location,
      isCompleted: false,
      alarmOffsetMinutes: normalizedOffset,
    );
  }

  bool _isValidTime(String value) {
    return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }
}
