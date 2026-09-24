// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '해칫 (HatchIt)';

  @override
  String get screenTimetable => '화면 1 · 시간표';

  @override
  String get screenMission => '화면 2 · 알람 미션';

  @override
  String get screenPet => '화면 3 · 펫 진화';

  @override
  String get screenMiniGame => '미니게임';

  @override
  String get themeMode => '테마';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get language => '언어';

  @override
  String get missionSample => '기상 미션 샘플';

  @override
  String get petStatus => '알 1일차 / 7일';

  @override
  String get miniGameHint => '휴대폰을 기울여 이동(센서 프리뷰)';

  @override
  String get ocrStub => '시간표 OCR(Gemini Vision) 연동 뼈대';
}
