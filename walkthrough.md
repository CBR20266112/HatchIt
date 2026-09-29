# HatchIt Gemini AI 비서 리팩터링 및 워크스루 (Walkthrough)

## 📌 개요
본 문서는 HatchIt(해칫)의 AI 비서 서비스(`GeminiAssistantService`) 점검 및 마스코트(1~16종) 성향/말투 동적 반영, 시간표 파싱 안정성 강화를 위한 리팩터링 작업, 마스코트 에셋(16종 40개, 총 640장) 100% 구축 내역과 향후 계획을 기록한 문서입니다.

---

## 🛠️ 지금까지 완료한 작업 (Completed Tasks)

### 1. `GeminiAssistantService` 코드 정밀 점검
- **호출 모델 확인**: Google Generative Language v1beta의 `gemini-1.5-flash` 모델 사용 확인
- **시간표 파싱 및 스키마 분석**:
  - `responseMimeType: 'application/json'`과 `temperature: 0.2`로 JSON 출력 안정성 확보 확인
  - `_extractJsonObject`를 통한 마크다운 백틱 및 텍스트 예외 방어 확인
  - 요일 기준(1~7) 및 시간 형식(24시간 HH:mm)의 명시성 부족 문제 식별
- **마스코트 성향 반영 여부 확인**:
  - 기존에는 마스코트 ID 파라미터가 없었으며, 시스템 프롬프트에 "고양이 AI 비서"로 하드코딩되어 있었음을 확인
  - 도메인 모델(`MascotSpeciesDefinition`)에 이미 1~16종의 마스코트 정보(`name`, `persona`, `signatureSuffix` 등)가 구축되어 있음을 파악

---

### 2. 마스코트 16종 성향 연동 및 프롬프트 고도화 리팩터링
- **파일**: [`lib/features/assistant/data/gemini_assistant_service.dart`](file:///c:/Users/vipgo/Dev/HatchIt/flutter_app/lib/features/assistant/data/gemini_assistant_service.dart)
  - `MascotSpeciesDefinition` 임포트
  - `ask()` 메서드에 선택적 파라미터 `int? speciesId` 추가
  - `MascotSpeciesDefinition.byId(speciesId ?? 1)`를 통해 마스코트 데이터 동적 조회
  - 시스템 프롬프트에 마스코트 고유 이름(`${species.name}`), 페르소나(`${species.persona}`), 시그니처 말끝 말투(`${species.signatureSuffix}`) 주입
  - 요일 규격 `day_of_week: 1(월요일) ~ 7(일요일)` 명시
  - 시간 형식 `24시간 형식 "HH:mm"` 규칙 명시

---

### 3. 마스코트 허브 화면 연동
- **파일**: [`lib/features/mascot/presentation/mascot_hub_screen.dart`](file:///c:/Users/vipgo/Dev/HatchIt/flutter_app/lib/features/mascot/presentation/mascot_hub_screen.dart)
  - `_processAssistantInput`에서 현재 활성화된 마스코트 프로필(`mascotProfileProvider`)의 `speciesId`를 조회
  - `_assistantService.ask(..., speciesId: profile?.speciesId)`로 전달하여 실제 사용자가 육성 중인 마스코트의 말투로 응답하도록 연결

---

### 4. 단위 테스트 및 검증 환경 구축
- **파일**: [`test/features/assistant/gemini_assistant_service_test.dart`](file:///c:/Users/vipgo/Dev/HatchIt/flutter_app/test/features/assistant/gemini_assistant_service_test.dart)
  - `CREATE_SCHEDULE` 시간표 생성 JSON 파싱 테스트
  - `SET_ALARM` 알람 설정 JSON 파싱 테스트
  - `CHAT` 일반 대화 JSON 파싱 테스트
  - 비정상 데이터 및 범위 초과 시 안전한 기본값(fallback) 방어 검증
  - 실제 API 키 주입 시 실서버 응답을 검증하는 Live API 테스트(부엉이 `speciesId: 2` 테스트 케이스 포함) 작성

---

### 5. 16종 마스코트 에셋 40종 표준화 및 100% 완성 (총 640장 완료)
- **스크립트**: `organize_mascots.py`, `clean_mascot_assets.py`, `final_mascot_sync.py`, `complete_all_mascots.py`, `verify_640_assets.py`
- 상위 원본 경로(`C:\Users\vipgo\Dev\HatchIt`)의 전종 에셋 팩을 연계하여 16종 전원 **40/40 (100%)** 표준화 완료:
  - **ID 01 고양이 (삼순이)**: `rmbg` 폴더 40종 1:1 매핑 복사 완료 (40/40)
  - **ID 02 부엉이 (올리)**: `2` 폴더 40종 덮어쓰기 복사 완료 (40/40)
  - **ID 03 거북이 (부기)**: `Boogi_Pack_Named_v3` 원본 커스텀 파일(`hmm_panic`, `blanket_cozy2`, `mission_fail2`, `eye_smile` 등) 매핑 완료 (40/40)
  - **ID 04 비버 (비비)**: `11_expr_sleepy` 보충 완료 (40/40)
  - **ID 05 나무늘보 (슬로)**: `reading.png` 기반 `hugging_book.png` 매핑 복제 완료 (40/40)
  - **ID 06 판다 (포포)**: `popo_11_expr_sleepy` 보충 완료 (40/40)
  - **ID 07 햄스터 (해찌)**: 전종 구비 완료 (40/40)
  - **ID 08 여우 (아랑)**: 전종 구비 완료 (40/40)
  - **ID 09 다람쥐 (람이)**: `rami_v2` 매핑 및 `sleeping.png` 기반 `expr_sleepy.png` 복제 완료 (40/40)
  - **ID 10 코기**: 전종 구비 완료 (40/40)
  - **ID 11 바다사자 (바루)**: 전종 구비 완료 (40/40)
  - **ID 12 까마귀 (까미)**: `Yqxq6UGL.png`(`expr_happy`) 매핑 보충 완료 (40/40)
  - **ID 13 수달 (다리)**: 전종 구비 완료 (40/40)
  - **ID 14 토끼 (라비)**: 전종 구비 완료 (40/40)
  - **ID 15 코알라 (알라)**: `Alla_Pack...` 40종 번호 접두사 제거 덮어쓰기 완료 (40/40)
  - **ID 16 오리 (덕이)**: `sleeping.png` 기반 `expr_sleepy.png` 복제 완료 (40/40)

---

## 📊 마스코트 1~16번 최종 에셋 보유 현황 (640 / 640 달성)

| 동물 ID | 마스코트 명칭 | 에셋 완성도 | 상태 |
| :---: | :---: | :---: | :---: |
| **01** | 고양이 (삼순이) | **40 / 40개** | ✅ 100% 완료 |
| **02** | 부엉이 (올리) | **40 / 40개** | ✅ 100% 완료 |
| **03** | 거북이 (부기) | **40 / 40개** | ✅ 100% 완료 |
| **04** | 비버 (비비) | **40 / 40개** | ✅ 100% 완료 |
| **05** | 나무늘보 (슬로) | **40 / 40개** | ✅ 100% 완료 |
| **06** | 판다 (포포) | **40 / 40개** | ✅ 100% 완료 |
| **07** | 햄스터 (해찌) | **40 / 40개** | ✅ 100% 완료 |
| **08** | 여우 (아랑) | **40 / 40개** | ✅ 100% 완료 |
| **09** | 다람쥐 (람이) | **40 / 40개** | ✅ 100% 완료 |
| **10** | 코기 | **40 / 40개** | ✅ 100% 완료 |
| **11** | 바다사자 (바루) | **40 / 40개** | ✅ 100% 완료 |
| **12** | 까마귀 (까미) | **40 / 40개** | ✅ 100% 완료 |
| **13** | 수달 (다리) | **40 / 40개** | ✅ 100% 완료 |
| **14** | 토끼 (라비) | **40 / 40개** | ✅ 100% 완료 |
| **15** | 코알라 (알라) | **40 / 40개** | ✅ 100% 완료 |
| **16** | 오리 (덕이) | **40 / 40개** | ✅ 100% 완료 |
| **합계** | **16종 마스코트** | **640 / 640개** | 🎉 **100% 완벽 달성** |

---

## 📋 변경된 주요 파일 및 차이 요약

| 파일 경로 | 주요 변경 내용 |
| :--- | :--- |
| `lib/features/assistant/data/gemini_assistant_service.dart` | `speciesId` 매개변수 추가, 16종 마스코트 페르소나 동적 주입, 요일(1~7)/24시간 형식(HH:mm) 규칙 명시 |
| `lib/features/mascot/presentation/mascot_hub_screen.dart` | `_processAssistantInput`에서 `speciesId: profile?.speciesId` 전달 연동 |
| `test/features/assistant/gemini_assistant_service_test.dart` | JSON 모델 파싱 및 방어 로직, 라이브 API 호출 유닛 테스트 신규 생성 |
| `assets/images/mascots/{1~16}/` | 16종 마스코트 전원 40종 표준 액션/감정 에셋 배치 완료 (총 640개 파일) |

---

## 🚀 앞으로 하게 될 작업 (Upcoming / Future Work)

1. **테스트 및 검증 실행 (Flutter 환경)**
   - 개발 환경 터미널에서 Flutter SDK PATH 설정 확인 후 `flutter test test/features/assistant/gemini_assistant_service_test.dart` 실행 검증
2. **pubspec.yaml 에셋 등록 확인**
   - `assets/images/mascots/` 1~16 하위 경로가 `pubspec.yaml`에 누락 없이 등록되어 있는지 최종 확인
3. **앱 UI 마스코트 뷰어/인터랙션 확인**
   - 마스코트 허브, 시간표, 알람 미션 화면에서 16종 동물들이 각 상태별 에셋을 문제없이 렌더링하는지 UI 점검
