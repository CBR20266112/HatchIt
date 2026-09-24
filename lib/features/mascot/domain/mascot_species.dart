import 'package:flutter/material.dart';

enum MascotRhythm { day, night }
enum MascotExecution { plan, burst }
enum MascotCognition { logic, text }
enum MascotEnergy { calm, active }

class MascotSpeciesDefinition {
  const MascotSpeciesDefinition({
    required this.id,
    required this.key,
    required this.name,
    required this.nickname,
    required this.traitCode,
    required this.rhythm,
    required this.execution,
    required this.cognition,
    required this.energy,
    required this.assetBasePath,
    this.persona = '',
    this.signatureSuffix = '',
    this.alarmDialogue = '',
    this.reminderDialogue = '',
    this.groomingDialogue = '',
  });

  final int id;
  final String key;
  final String name;
  final String nickname;
  final String traitCode;
  final MascotRhythm rhythm;
  final MascotExecution execution;
  final MascotCognition cognition;
  final MascotEnergy energy;
  final String assetBasePath;
  final String persona;
  final String signatureSuffix;
  final String alarmDialogue;
  final String reminderDialogue;
  final String groomingDialogue;

  static const List<MascotSpeciesDefinition> all = [
    MascotSpeciesDefinition(
      id: 1,
      key: 'cat',
      name: '삼순이',
      nickname: '벼락치기 삼색냥',
      traitCode: '1100',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/1',
      persona:
          '호기심 많고 사랑스러운 삼색 고양이. 평소엔 창가에서 뒹굴거리지만 마감 직전엔 놀라운 집중력을 발휘하는 반전 매력의 벼락치기 비서.',
      signatureSuffix: '~냥',
      alarmDialogue: '일어날 시간이다냥! 얼른 미션 풀고 1교시 세이프하자냥!',
      reminderDialogue: '과제 마감 1시간 전이다냥! 지금 집중하면 충분히 끝낼 수 있다냥!',
      groomingDialogue: '골골골... 털 빗어주니 정말 시원하다냥! 털뭉치 선물이다냥~',
    ),
    MascotSpeciesDefinition(
      id: 2,
      key: 'owl',
      name: '부엉이',
      nickname: '올리',
      traitCode: '1000',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.plan,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/2',
    ),
    MascotSpeciesDefinition(
      id: 3,
      key: 'turtle',
      name: '거북이',
      nickname: '터틀',
      traitCode: '0000',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/3',
    ),
    MascotSpeciesDefinition(
      id: 4,
      key: 'beaver',
      name: '비버',
      nickname: '비비',
      traitCode: '0001',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/4',
    ),
    MascotSpeciesDefinition(
      id: 5,
      key: 'sloth',
      name: '나무늘보',
      nickname: '슬로',
      traitCode: '1110',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.burst,
      cognition: MascotCognition.text,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/5',
    ),
    MascotSpeciesDefinition(
      id: 6,
      key: 'panda',
      name: '판다',
      nickname: '포포',
      traitCode: '0110',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.burst,
      cognition: MascotCognition.text,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/6',
    ),
    MascotSpeciesDefinition(
      id: 7,
      key: 'hamster',
      name: '햄스터',
      nickname: '찌라',
      traitCode: '1111',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.burst,
      cognition: MascotCognition.text,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/7',
    ),
    MascotSpeciesDefinition(
      id: 8,
      key: 'fox',
      name: '여우',
      nickname: '호야',
      traitCode: '1101',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/8',
    ),
    MascotSpeciesDefinition(
      id: 9,
      key: 'squirrel',
      name: '다람쥐',
      nickname: '다라',
      traitCode: '0010',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/9',
    ),
    MascotSpeciesDefinition(
      id: 10,
      key: 'corgi',
      name: '웰시코기',
      nickname: '코기',
      traitCode: '0111',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.burst,
      cognition: MascotCognition.text,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/10',
    ),
    MascotSpeciesDefinition(
      id: 11,
      key: 'sealion',
      name: '물개',
      nickname: '바디',
      traitCode: '0100',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/11',
    ),
    MascotSpeciesDefinition(
      id: 12,
      key: 'crow',
      name: '까마귀',
      nickname: '까미',
      traitCode: '1011',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/12',
    ),
    MascotSpeciesDefinition(
      id: 13,
      key: 'otter',
      name: '수달',
      nickname: '다리',
      traitCode: '1001',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.plan,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/13',
    ),
    MascotSpeciesDefinition(
      id: 14,
      key: 'rabbit',
      name: '토끼',
      nickname: '토비',
      traitCode: '0011',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/14',
    ),
    MascotSpeciesDefinition(
      id: 15,
      key: 'koala',
      name: '코알라',
      nickname: '코리',
      traitCode: '1010',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/15',
    ),
    MascotSpeciesDefinition(
      id: 16,
      key: 'duck',
      name: '오리',
      nickname: '덕이',
      traitCode: '0101',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/16',
    ),
  ];

  static MascotSpeciesDefinition byId(int id) {
    return all.firstWhere((element) => element.id == id, orElse: () => all.first);
  }

  static int calculateSpeciesId({
    required bool isNight,
    required bool isBurst,
    required bool isText,
    required bool isActive,
  }) {
    final binaryString =
        '${isNight ? 1 : 0}${isBurst ? 1 : 0}${isText ? 1 : 0}${isActive ? 1 : 0}';
    const mapping = {
      '1100': 1,
      '1000': 2,
      '0000': 3,
      '0001': 4,
      '1110': 5,
      '0110': 6,
      '1111': 7,
      '1101': 8,
      '0010': 9,
      '0111': 10,
      '0100': 11,
      '1011': 12,
      '1001': 13,
      '0011': 14,
      '1010': 15,
      '0101': 16,
    };
    return mapping[binaryString] ?? 1;
  }
}

class MascotThemeToken {
  const MascotThemeToken({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.surfaceTint,
    required this.emotionHot,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color surfaceTint;
  final Color emotionHot;
}

const Map<int, MascotThemeToken> mascotThemeTokens = {
  1: MascotThemeToken(
    primary: Color(0xFF363238),
    secondary: Color(0xFFFCFAF7),
    accent: Color(0xFFFFA858),
    surfaceTint: Color(0xFFE4A03C),
    emotionHot: Color(0xFFFFB7B2),
  ),
  2: MascotThemeToken(
    primary: Color(0xFFA8733D),
    secondary: Color(0xFFF6D9A8),
    accent: Color(0xFFF2B84B),
    surfaceTint: Color(0xFFFFF2DC),
    emotionHot: Color(0xFFE86A33),
  ),
  3: MascotThemeToken(
    primary: Color(0xFF9DBF8E),
    secondary: Color(0xFFDDE7B8),
    accent: Color(0xFF7CBF6F),
    surfaceTint: Color(0xFFEEF6E9),
    emotionHot: Color(0xFFFF8A65),
  ),
  4: MascotThemeToken(
    primary: Color(0xFF8B5A3A),
    secondary: Color(0xFFC48A5A),
    accent: Color(0xFFF2B56B),
    surfaceTint: Color(0xFFF9F0E7),
    emotionHot: Color(0xFFFF7043),
  ),
  5: MascotThemeToken(
    primary: Color(0xFF8D6548),
    secondary: Color(0xFFC39A73),
    accent: Color(0xFFA27B5C),
    surfaceTint: Color(0xFFF5ECE3),
    emotionHot: Color(0xFFFF8A65),
  ),
  6: MascotThemeToken(
    primary: Color(0xFF2F3136),
    secondary: Color(0xFFF4F1E8),
    accent: Color(0xFF8BC34A),
    surfaceTint: Color(0xFFF2F5ED),
    emotionHot: Color(0xFFFF6E6E),
  ),
  7: MascotThemeToken(
    primary: Color(0xFFD4B08A),
    secondary: Color(0xFFF3DFC7),
    accent: Color(0xFFF0C94D),
    surfaceTint: Color(0xFFFFF5E8),
    emotionHot: Color(0xFFFF7043),
  ),
  8: MascotThemeToken(
    primary: Color(0xFFD67A45),
    secondary: Color(0xFFFFF2E2),
    accent: Color(0xFFF4B000),
    surfaceTint: Color(0xFFFFF1E6),
    emotionHot: Color(0xFFFF5A4F),
  ),
  9: MascotThemeToken(
    primary: Color(0xFFC18C4D),
    secondary: Color(0xFFF6DFC0),
    accent: Color(0xFF8FBF5E),
    surfaceTint: Color(0xFFFFF3E2),
    emotionHot: Color(0xFFFF7A59),
  ),
  10: MascotThemeToken(
    primary: Color(0xFFE7A248),
    secondary: Color(0xFFFFF3DF),
    accent: Color(0xFF7BC96F),
    surfaceTint: Color(0xFFFFF5E8),
    emotionHot: Color(0xFFFF6B5E),
  ),
  11: MascotThemeToken(
    primary: Color(0xFF8FA8C4),
    secondary: Color(0xFFF3F6FA),
    accent: Color(0xFF7ED0E6),
    surfaceTint: Color(0xFFECF4FA),
    emotionHot: Color(0xFFFF6F61),
  ),
  12: MascotThemeToken(
    primary: Color(0xFF232733),
    secondary: Color(0xFFD7DEE9),
    accent: Color(0xFF6F7EC9),
    surfaceTint: Color(0xFFEDF1F8),
    emotionHot: Color(0xFFFF5A45),
  ),
  13: MascotThemeToken(
    primary: Color(0xFF9A6B4C),
    secondary: Color(0xFFF3E0CB),
    accent: Color(0xFFE7A55C),
    surfaceTint: Color(0xFFF8EFE6),
    emotionHot: Color(0xFFFF7A59),
  ),
  14: MascotThemeToken(
    primary: Color(0xFFF8F5EE),
    secondary: Color(0xFFF9D8DF),
    accent: Color(0xFF9BD4B5),
    surfaceTint: Color(0xFFFFF7FB),
    emotionHot: Color(0xFFFF6B6B),
  ),
  15: MascotThemeToken(
    primary: Color(0xFFA8ADB5),
    secondary: Color(0xFFF2EFF0),
    accent: Color(0xFFD7B6C7),
    surfaceTint: Color(0xFFF5F3F7),
    emotionHot: Color(0xFFFF7A7A),
  ),
  16: MascotThemeToken(
    primary: Color(0xFFF6D86E),
    secondary: Color(0xFFFFF6D9),
    accent: Color(0xFFFFA86A),
    surfaceTint: Color(0xFFFFFBEF),
    emotionHot: Color(0xFFFF6A3D),
  ),
};

class MascotThemePalette extends ThemeExtension<MascotThemePalette> {
  const MascotThemePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.surfaceTint,
    required this.emotionHot,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color surfaceTint;
  final Color emotionHot;

  factory MascotThemePalette.fromSpeciesId(int? speciesId) {
    final token = mascotThemeTokens[speciesId] ?? mascotThemeTokens[1]!;
    return MascotThemePalette(
      primary: token.primary,
      secondary: token.secondary,
      accent: token.accent,
      surfaceTint: token.surfaceTint,
      emotionHot: token.emotionHot,
    );
  }

  @override
  MascotThemePalette copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? surfaceTint,
    Color? emotionHot,
  }) {
    return MascotThemePalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      emotionHot: emotionHot ?? this.emotionHot,
    );
  }

  @override
  MascotThemePalette lerp(ThemeExtension<MascotThemePalette>? other, double t) {
    if (other is! MascotThemePalette) {
      return this;
    }
    return MascotThemePalette(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t) ?? surfaceTint,
      emotionHot: Color.lerp(emotionHot, other.emotionHot, t) ?? emotionHot,
    );
  }
}
