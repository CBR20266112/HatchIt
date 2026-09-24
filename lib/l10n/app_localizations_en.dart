// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HatchIt';

  @override
  String get screenTimetable => 'Screen 1 · Timetable';

  @override
  String get screenMission => 'Screen 2 · Mission Alarm';

  @override
  String get screenPet => 'Screen 3 · Pet Evolution';

  @override
  String get screenMiniGame => 'Mini Game';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get missionSample => 'Wake-up mission sample';

  @override
  String get petStatus => 'Egg Day 1 / 7';

  @override
  String get miniGameHint => 'Tilt your phone to move (sensors preview).';

  @override
  String get ocrStub => 'OCR timetable parsing (Gemini Vision) skeleton';
}
