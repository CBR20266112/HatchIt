# HatchIt

HatchIt은 사용자의 생활 패턴(공부, 수면, 운동, 식사 등)에 반응해 캐릭터를 성장시키는 Flutter 기반 반려 캐릭터 앱 프로젝트입니다.

- **앱 이름**: HatchIt
- **패키지명**: `com.hatchit.campus`
- **기술 스택**: Flutter / Dart
- **주 타깃 플랫폼**: Android (웹은 개발/미리보기 용도)

---

## 1) 프로젝트 목적

이 프로젝트는 단순한 투두 앱이 아니라, 다음 목표를 가진 **학습/개인 프로젝트형 앱**입니다.

1. 습관 데이터를 기록하고,
2. 캐릭터 반응(표정/행동/상태 변화)으로 피드백을 주며,
3. 장기적으로 사용자의 자기관리 동기를 높이는 것.

---

## 2) 현재 진행 상태

### 완료된 항목
- Flutter 기본 프로젝트 구조 생성
- 주요 에셋(마스코트 이미지 세트) 반영
- 개발 백업 브랜치 생성 및 원격 푸시

### 진행 중 항목
- 일부 마스코트 이미지(`idle.png`, `grooming.png`)의 고품질 투명화/정제
  - 자동 누끼 처리로 1차 시도 완료
  - 잔여 노이즈/경계 품질 이슈로 재정제 필요

---

## 3) 브랜치 전략 (중요)

> **원칙: `main`은 안정화용, 개발은 별도 브랜치에서 진행**

### 운영 규칙
- `main`
  - 배포/안정화 기준 브랜치
  - 검증된 커밋만 반영
- `dev/*` 또는 `backup/*`
  - 기능 개발, 실험, 중간 백업용
  - 사용자가 명시적으로 지시하기 전까지 `main` 직접 반영 금지

### 권장 브랜치 네이밍
- 기능 개발: `dev/feature-<topic>`
- 버그 수정: `dev/fix-<topic>`
- 중간 백업: `dev/backup-YYYYMMDD-<topic>`

---

## 4) 로컬 개발 환경

이 프로젝트는 고정된 버전 환경을 기준으로 합니다.

- **Flutter**: `3.35.4`
- **Dart**: `3.9.2`

> 주의: 버전 업그레이드는 호환성 이슈를 만들 수 있으므로, 별도 합의 없이 진행하지 않습니다.

---

## 5) 실행 방법

### 5-1. 의존성 설치
```bash
cd /home/user/flutter_app
flutter pub get
```

### 5-2. 분석(권장)
```bash
cd /home/user/flutter_app
flutter analyze
```

### 5-3. 웹 미리보기 (개발 확인용)
```bash
cd /home/user/flutter_app
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```

### 5-4. Android 빌드
```bash
cd /home/user/flutter_app
flutter build apk --release
```

---

## 6) 프로젝트 구조

```text
flutter_app/
├─ lib/                      # 앱 소스 코드 (화면, 로직, 상태관리)
├─ assets/
│  └─ images/
│     └─ mascots/            # 마스코트 이미지 리소스
├─ android/                  # Android 네이티브 설정
├─ web/                      # 웹 미리보기 관련 설정
├─ pubspec.yaml              # 의존성/에셋 등록
└─ README.md                 # 프로젝트 문서
```

---

## 7) 에셋 작업 가이드

현재 마스코트 에셋은 품질이 앱 인상에 직접 영향을 줍니다.

- 우선순위
  1. 캐릭터 경계 깔끔함
  2. 배경 완전 투명
  3. 가이드선/텍스트 노이즈 제거
- 권장 사항
  - 가능하면 원본 투명 PNG를 확보해서 사용
  - 자동 처리 결과는 항상 시각 검수 후 반영

---

## 8) 커밋/푸시 규칙

### 커밋 메시지 예시
- `feat: 습관 기록 화면 추가`
- `fix: 캐릭터 상태 전환 버그 수정`
- `chore: 마스코트 에셋 1차 백업`
- `docs: README 상세화`

### 기본 흐름
```bash
cd /home/user/flutter_app
git checkout dev/feature-xxx
git add .
git commit -m "feat: ..."
git push -u origin dev/feature-xxx
```

---

## 9) 협업/운영 메모

- `main` 반영은 “안정화 완료” 기준으로만 진행
- README는 작업 흐름이 바뀔 때마다 같이 업데이트
- 중요한 리소스 변경(에셋 대량 교체 등)은 백업 브랜치 생성 후 진행

---

## 10) 다음 액션 (권장)

1. `idle.png`, `grooming.png` 고품질 소스 재확보
2. 마스코트 정제본 확정 후 앱 내 반영 테스트
3. 화면별 QA 체크리스트 작성
4. 안정화 시점에 `main` 반영

---

문의/개선 요청은 이슈나 브랜치 단위로 남겨 관리하는 것을 권장합니다.
