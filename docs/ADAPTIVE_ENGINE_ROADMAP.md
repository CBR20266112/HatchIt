# HatchIt Adaptive Tree Engine 문서화

## 1) 이번 변경 요약

### A. 알 부화 질문 시스템
- 기존: 4비트 고정형(축 4개 + 이분 선택)
- 변경: **7일 동적 적응형 분기 엔진(Adaptive Tree Engine)**
  - Day1~2: 대분류 스크리닝
  - Day3~5: 앞선 선택 결과 기반 트랙별 심화 질문
  - Day6~7: 실행 템포/마감 스타일 핀포인트

### B. 최종 판정 방식
- `MascotDomainCategory`(nature/humanities/artPhysical/service/education/bohemian) 기준 누적 점수
- `burstPaceScore`, `deepFocusScore` 함께 사용
- `calculateAdaptiveMascotId(...)`로 16종 중 1종 판정

### C. 마스코트 스펙
- 16종별 이름/닉네임/말투/시그니처 대사(알람/마감/빗질) 반영

---

## 2) 코드 변경 파일

### 2.1 `lib/features/mascot/domain/mascot_species.dart`
- `MascotDomainCategory` enum 추가
- `calculateAdaptiveMascotId(...)` 함수 추가
- `MascotSpeciesDefinition.category` getter 추가 (id 기반 카테고리 판별)
- 16종 마스코트 페르소나/대사 상세화

### 2.2 `lib/features/mascot/domain/mascot_profile.dart`
- 점수 필드 확장:
  - `natureScore`, `humanitiesScore`, `artPhysicalScore`
  - `serviceScore`, `educationScore`, `bohemianScore`
  - `burstPaceScore`, `deepFocusScore`
- `copyWith`, `toMap`, `fromMap`, `defaults` 반영

### 2.3 `lib/core/database/app_database.dart`
- `mascot_profile` 테이블 컬럼 확장
- 신규 컬럼에 대해 `_ensureColumnExists` 추가하여 기존 DB 마이그레이션 호환

### 2.4 `lib/features/mascot/data/mascot_profile_dao.dart`
- 메모리 프로필 초기값에 신규 점수 필드 반영

### 2.5 `lib/features/mascot/presentation/mascot_controller.dart`
- 기존 `PersonalityAxis` 기반 입력 제거
- `AdaptiveEggAnswerPayload` 도입
- `submitDailyEggAnswer(payload: ...)`로 점수 누적 및 Day7 시 최종 판정

### 2.6 `lib/features/mascot/presentation/mascot_hub_screen.dart`
- 고정 질문 배열 제거
- `_resolveAdaptiveEggQuestion(profile)` 도입
- 옵션 개수 가변(2~4개/3개) UI 대응
- Day3~5 트랙 심화 분기 로직 반영

---

## 3) 판정 로직(요약)

1. 매일 답변 시 payload 점수 누적
2. Day7(eggCrackDay >= 7) 도달 시:
   - 카테고리 최고점 = `dominantCategory`
   - `burstPaceScore >= 2` 여부
   - `deepFocusScore >= 2` 여부
3. `calculateAdaptiveMascotId`로 최종 speciesId 결정
4. 상태를 `MascotStage.hatched`로 전환

---

## 4) 현재 앱 방향성 (Product Direction)

### 핵심 비전
> 단순 일정앱이 아니라, 7일간의 자기 인지 데이터로 “학습/과제 수행 스타일”을 반영한 캐릭터 코치를 제공하는 **대학생 생산성 동반자 앱**.

### UX 전략
- 첫 7일: 캐릭터 부화 몰입
- 부화 후: 개인 성향형 마스코트 코칭
- 일상 루프:
  - 알람/미션/일정 관리
  - 마스코트 상호작용(쓰다듬기/밥주기/빗질)
  - 성향 기반 멘트 피드백

### 향후 우선순위
1. Day3~5 질문 텍스트 더 세밀화(A/B 실험)
2. 판정 결과 해설 화면(왜 이 마스코트인지 근거 표시)
3. 대화형 코치(학사 일정/과제 마감과 연동된 문맥 알림)
4. 성향 변화 추적(학기 단위 재진단)

---

## 5) 검증 상태
- `flutter analyze` 통과 (No issues found)
- 웹 release 빌드 성공
- Python preview 서버(5060) 재기동 완료

---

## 6) 브랜치 운영 가이드
- `main`: 배포 가능한 안정 버전
- `dev/adaptive-engine`: 적응형 엔진 및 마스코트 스펙 확장 개발 브랜치

권장 정책:
- 기능 추가는 dev 브랜치에서 진행
- 기능 완료 후 PR/리뷰 후 main 머지
- 릴리즈 태그는 main에서만 생성
