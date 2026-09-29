# HatchIt (해칫) — Developer & Architecture Reference

> **브랜치 안내**: 이 `develop` 브랜치는 내부 개발·아키텍처·테스트 명세용입니다.
> 일반 사용자 소개 페이지는 [`main` 브랜치 README](../../blob/main/README.md)를 참조하세요.

---

## 🏗️ 프로젝트 아키텍처

```
flutter_app/
├── lib/
│   ├── core/
│   │   ├── database/          # SQLite DAO (sqflite 2.4)
│   │   ├── permissions/       # 권한 요청 헬퍼
│   │   └── settings/          # SettingsController (Riverpod)
│   └── features/
│       ├── assistant/         # Gemini AI 비서 서비스
│       │   └── data/
│       │       └── gemini_assistant_service.dart
│       ├── mascot/            # 마스코트 도메인 + 허브 화면
│       │   ├── domain/
│       │   │   └── mascot_species.dart   # 16종 MascotSpeciesDefinition
│       │   └── presentation/
│       │       ├── mascot_hub_screen.dart
│       │       └── mascot_controller.dart
│       ├── schedules/         # 시간표 DAO + 위젯
│       ├── mission/           # 기상 미션 + 알람
│       ├── minigame/          # 캠퍼스 오락실 미니게임 3종
│       ├── daily_records/     # 7일 부화 Q&A
│       ├── events/            # 이벤트 뱃지
│       └── home/              # BottomNav Shell
├── assets/
│   └── images/
│       └── mascots/
│           └── {1..16}/      # 40종 표준 PNG × 16종 = 640장
└── test/
    └── features/
        └── assistant/
            └── gemini_assistant_service_test.dart
```

### 핵심 기술 스택

| 영역 | 기술 |
|------|------|
| **상태관리** | Riverpod 2.6.1 (`flutter_riverpod`) |
| **로컬 DB** | sqflite 2.4.2 (SQLite DAO) |
| **AI 비서** | Google Generative Language v1beta — `gemini-1.5-flash` |
| **알림/알람** | flutter_local_notifications 18 + android_alarm_manager_plus 4 |
| **HTTP** | http 1.5.0 (순수 REST, 외부 패키지 최소화) |
| **국제화** | flutter_localizations + intl 0.20.2 (한국어 기본) |

---

## 🦎 16종 마스코트 도메인 모델

파일: [`lib/features/mascot/domain/mascot_species.dart`](lib/features/mascot/domain/mascot_species.dart)

### `MascotSpeciesDefinition` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | `int` | 1 ~ 16 고유 ID |
| `key` | `String` | 영문 식별자 (`cat`, `owl`, …) |
| `name` | `String` | 한국어 동물명 (`고양이`, `부엉이`, …) |
| `nickname` | `String` | 앱 내 마스코트 닉네임 (`삼순이`, `올리`, …) |
| `persona` | `String` | AI 비서 시스템 프롬프트용 성격 설명 |
| `signatureSuffix` | `String` | 말끝 시그니처 말투 (`~냥`, `~부엉`, …) |
| `alarmDialogue` | `String` | 기상 알람 발화 |
| `reminderDialogue` | `String` | 마감 리마인더 발화 |
| `groomingDialogue` | `String` | 빗질(그루밍) 완료 발화 |
| `rhythm` | `MascotRhythm` | 올빼미형 / 아침형 / 유연형 |
| `execution` | `MascotExecution` | 계획형 / 즉흥형 / 지속형 |

### 16종 ID 매핑

| ID | 동물명 | 닉네임 | 시그니처 | 카테고리 |
|----|--------|--------|----------|----------|
| 1 | 고양이 | 삼순이 | ~냥 | nature |
| 2 | 부엉이 | 올리 | ~부엉 | service |
| 3 | 거북이 | 부기 | ~부기 | education |
| 4 | 비버 | 비비 | ~비비 | nature |
| 5 | 나무늘보 | 슬로 | ~슬로 | nature |
| 6 | 판다 | 포포 | ~포포 | nature |
| 7 | 햄스터 | 해찌 | ~해찌 | nature |
| 8 | 여우 | 아랑 | ~아랑 | nature |
| 9 | 다람쥐 | 람이 | ~람이 | nature |
| 10 | 웰시코기 | 코기 | ~코기 | service |
| 11 | 바다사자 | 바루 | ~바루 | nature |
| 12 | 까마귀 | 까미 | ~까미 | bohemian |
| 13 | 수달 | 다리 | ~다리 | nature |
| 14 | 토끼 | 라비 | ~라비 | nature |
| 15 | 코알라 | 알라 | ~알라 | nature |
| 16 | 오리 | 덕이 | ~덕이 | bohemian |

---

## 🖼️ 40종 표준 에셋 파이프라인 (총 640장)

경로: `assets/images/mascots/{id}/{action}.png`
규격: **1024×1024 RGBA 투명 PNG**

### 40종 표준 파일명

```
기본/액션(8): idle, grooming, reading, typing, waving, jump, sleeping, curious_tap
표정(6):     expr_happy, expr_curious, expr_sleepy, expr_surprised, expr_pouty, expr_sad_teary
비서(4):     feed_eating, feed_full, groom_sparkle, pet_snuggle
알람/미션(4): alarm_panic, wake_drowsy, mission_clear, mission_fail
수업/일정(3): study_burn, class_nodding, campus_walk
미니게임(5): keycap_bite, stealth_alert, butt_up, particle_fur_1, particle_fur_2
부화(2):     egg_hatch, hold_furball
개성(8):     idea_bulb, coffee_sip, peek_box, blanket_cozy, clover_luck,
             magnify_study, hugging_book, cheer_shout
```

**검증 결과 (2026-09-29 기준)**: 16종 전원 40/40 **640 / 640장 100% 완성** ✅

---

## 🤖 `GeminiAssistantService` 상세 명세

파일: [`lib/features/assistant/data/gemini_assistant_service.dart`](lib/features/assistant/data/gemini_assistant_service.dart)

### 메서드 시그니처

```dart
Future<AssistantResponse> ask({
  required String userInput,
  required String apiKey,
  required DateTime now,
  int? speciesId,   // 마스코트 ID (1~16), null이면 고양이(1) 기본값
}) async
```

### 시스템 프롬프트 동적 바인딩

`speciesId`로 `MascotSpeciesDefinition.byId(speciesId ?? 1)`를 조회한 뒤:
- `species.name` → 마스코트 이름 (`너는 AI 비서 마스코트 '고양이'이다.`)
- `species.persona` → 성격/페르소나
- `species.signatureSuffix` → 말끝 말투 규칙 (`반드시 말끝마다 '~냥'을 붙여라`)

### 응답 JSON 스키마

```json
{
  "action": "CREATE_SCHEDULE | SET_ALARM | TOGGLE_ALARM | CHAT",
  "dialogue": "한국어 한 문장 (마스코트 말투 적용)",
  "mascot_emotion": "waving | study_burn | alarm_panic | expr_happy | ...",
  "schedule_data": {
    "title": "수업명 또는 일정명",
    "day_of_week": 2,         // 1(월)~7(일)
    "start_time": "14:00",   // 24시간 HH:mm
    "end_time": "16:00",
    "color_index": 3          // 0~9
  },
  "alarm_data": {
    "target_time": "08:30",  // 24시간 HH:mm
    "is_enabled": true
  }
}
```

### API 설정

| 항목 | 값 |
|------|----|
| 모델 | `gemini-1.5-flash` |
| 엔드포인트 | `https://generativelanguage.googleapis.com/v1beta/models` |
| temperature | `0.2` |
| topP | `0.9` |
| responseMimeType | `application/json` |

### API Key 주입 우선순위

1. 앱 내 설정 (`settingsControllerProvider.geminiApiKey`)
2. 빌드 타임 주입 (`--dart-define=GEMINI_API_KEY=xxx`)

---

## 🧪 로컬 실행 및 테스트

### 단위 테스트 실행

```bash
# JSON 모델 파싱 / fallback 방어 로직 테스트 (오프라인)
flutter test test/features/assistant/gemini_assistant_service_test.dart

# Gemini API 라이브 호출 테스트 (키 필요)
flutter test test/features/assistant/gemini_assistant_service_test.dart \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY
```

### Android 디바이스 실행

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY
```

### 웹 서빙 (포트 5060)

```bash
flutter run -d chrome --web-port=5060 \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY
```

---

## 📝 워크스루 및 작업 히스토리

전체 작업 흐름 및 에셋 파이프라인 구축 과정은 [`walkthrough.md`](walkthrough.md)를 참조하세요.
