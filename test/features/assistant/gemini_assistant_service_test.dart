import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hatchit/features/assistant/data/gemini_assistant_service.dart';

void main() {
  group('GeminiAssistantService Model & Parsing Tests', () {
    test('일정 추가 JSON 파싱 테스트 (CREATE_SCHEDULE)', () {
      final sampleJson = {
        'action': 'CREATE_SCHEDULE',
        'dialogue': '화요일 2시 모바일프로그래밍 수업을 추가했어!',
        'mascot_emotion': 'study_burn',
        'schedule_data': {
          'title': '모바일프로그래밍',
          'day_of_week': 2,
          'start_time': '14:00',
          'end_time': '16:00',
          'color_index': 3,
        },
      };

      final response = AssistantResponse.fromJson(sampleJson);

      expect(response.action, AssistantAction.createSchedule);
      expect(response.dialogue, '화요일 2시 모바일프로그래밍 수업을 추가했어!');
      expect(response.mascotEmotion, 'study_burn');
      expect(response.scheduleData, isNotNull);
      expect(response.scheduleData!.title, '모바일프로그래밍');
      expect(response.scheduleData!.dayOfWeek, 2);
      expect(response.scheduleData!.startTime, '14:00');
      expect(response.scheduleData!.endTime, '16:00');
      expect(response.scheduleData!.colorIndex, 3);
    });

    test('알람 설정 JSON 파싱 테스트 (SET_ALARM)', () {
      final sampleJson = {
        'action': 'SET_ALARM',
        'dialogue': '내일 아침 7시 30분에 깨워줄게!',
        'mascot_emotion': 'alarm_panic',
        'alarm_data': {
          'target_time': '07:30',
          'is_enabled': true,
        },
      };

      final response = AssistantResponse.fromJson(sampleJson);

      expect(response.action, AssistantAction.setAlarm);
      expect(response.alarmData, isNotNull);
      expect(response.alarmData!.targetTime, '07:30');
      expect(response.alarmData!.isEnabled, isTrue);
    });

    test('일반 대화 JSON 파싱 테스트 (CHAT)', () {
      final sampleJson = {
        'action': 'CHAT',
        'dialogue': '오늘도 힘내보자냥!',
        'mascot_emotion': 'expr_happy',
      };

      final response = AssistantResponse.fromJson(sampleJson);

      expect(response.action, AssistantAction.chat);
      expect(response.dialogue, '오늘도 힘내보자냥!');
      expect(response.scheduleData, isNull);
      expect(response.alarmData, isNull);
    });

    test('비정상 데이터 및 기본값 fallback 방어 로직 검증', () {
      final malformedScheduleJson = {
        'title': '',
        'day_of_week': 99, // 1~7 범위를 벗어남
        'start_time': 'invalid-time',
        'end_time': null,
        'color_index': 'invalid',
      };

      final schedule = AssistantScheduleData.fromJson(malformedScheduleJson);

      expect(schedule.title, '새 일정'); // fallback
      expect(schedule.dayOfWeek, 7); // max 7 제한
      expect(schedule.startTime, '08:30'); // _normalizeTime fallback
      expect(schedule.endTime, '08:30'); // fallback
      expect(schedule.colorIndex, 0); // fallback
    });

    test('LocalScheduleParser 오프라인 로컬 규칙 파서 테스트', () {
      final now = DateTime(2026, 9, 29, 10, 0); // 화요일 (weekday = 2)
      final result = LocalScheduleParser.parse(
        '내일 오후 2시 자료구조 일정 추가해줘',
        now: now,
        speciesId: 1,
      );

      expect(result.action, AssistantAction.createSchedule);
      expect(result.scheduleData, isNotNull);
      expect(result.scheduleData!.dayOfWeek, 3); // 수요일 (화+1)
      expect(result.scheduleData!.startTime, '14:00');
      expect(result.scheduleData!.endTime, '15:00');
      expect(result.scheduleData!.title, '자료구조');
    });

    test('LocalScheduleParser 동아리 회의 / 점심 약속 파싱 테스트', () {
      final now = DateTime(2026, 9, 29, 10, 0);
      final result = LocalScheduleParser.parse(
        '금요일 19시 동아리 회의',
        now: now,
        speciesId: 1,
      );

      expect(result.action, AssistantAction.createSchedule);
      expect(result.scheduleData!.dayOfWeek, 5); // 금요일
      expect(result.scheduleData!.startTime, '19:00');
      expect(result.scheduleData!.endTime, '20:00');
      expect(result.scheduleData!.title, '동아리 회의');
    });

    test('LocalScheduleParser 한국어 조사 후처리 테스트', () {
      final now = DateTime(2026, 9, 29, 10, 0); // 화요일
      final r1 = LocalScheduleParser.parse(
        '17시까지 순천역 도착',
        now: now,
        speciesId: 1,
      );
      expect(r1.scheduleData!.title, '순천역 도착');
      expect(r1.scheduleData!.startTime, '17:00');
      expect(r1.scheduleData!.date, isNotNull);

      final r2 = LocalScheduleParser.parse(
        '9시에 신대지구 식당 예약',
        now: now,
        speciesId: 1,
      );
      expect(r2.scheduleData!.title, '신대지구 식당 예약');
      expect(r2.scheduleData!.startTime, '09:00');
      expect(r2.scheduleData!.date, isNotNull);
    });
  });

  group('GeminiAssistantService Live API Test', () {
    // 환경변수 GEMINI_API_KEY 또는 dart-define GEMINI_API_KEY 확인
    final apiKey = Platform.environment['GEMINI_API_KEY'] ??
        const String.fromEnvironment('GEMINI_API_KEY');

    test(
      '실제 Gemini API 호출 및 시간표 파싱 응답 확인',
      () async {
        const service = GeminiAssistantService();
        final now = DateTime(2026, 9, 29, 14, 0); // 화요일

        final response = await service.ask(
          userInput: '화요일 오후 2시부터 4시까지 모바일프로그래밍 수업 일정 등록해줘',
          apiKey: apiKey,
          now: now,
          speciesId: 2, // 부엉이 (~부엉)
        );

        // ignore: avoid_print
        print('Live API 응답 Action: ${response.action}');
        // ignore: avoid_print
        print('Live API 대사: ${response.dialogue}');
        // ignore: avoid_print
        print('Live API 일정: ${response.scheduleData?.title}, ${response.scheduleData?.startTime}~${response.scheduleData?.endTime}');

        expect(response.action, AssistantAction.createSchedule);
        expect(response.scheduleData, isNotNull);
        expect(response.scheduleData!.dayOfWeek, 2); // 화요일
        expect(response.dialogue.isNotEmpty, isTrue);
      },
      skip: apiKey.isEmpty
          ? 'GEMINI_API_KEY 환경변수가 설정되지 않아 실서버 테스트를 스킵합니다. (실행방법: flutter test --dart-define=GEMINI_API_KEY=your_key)'
          : null,
    );
  });
}
