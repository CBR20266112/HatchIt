import 'package:flutter/material.dart';

enum MascotRhythm { day, night }
enum MascotExecution { plan, burst }
enum MascotCognition { logic, text }
enum MascotEnergy { calm, active }

enum MascotDomainCategory {
  nature,
  humanities,
  artPhysical,
  service,
  education,
  bohemian,
}

int calculateAdaptiveMascotId({
  required MascotDomainCategory dominantCategory,
  required bool isBurstPaced,
  required bool isDeepFocus,
}) {
  switch (dominantCategory) {
    case MascotDomainCategory.nature:
      if (isBurstPaced) {
        return isDeepFocus ? 1 : 13;
      }
      return isDeepFocus ? 2 : 4;
    case MascotDomainCategory.humanities:
      if (isBurstPaced) {
        return isDeepFocus ? 8 : 12;
      }
      return isDeepFocus ? 5 : 9;
    case MascotDomainCategory.artPhysical:
      if (isBurstPaced) {
        return isDeepFocus ? 10 : 11;
      }
      return isDeepFocus ? 14 : 6;
    case MascotDomainCategory.service:
      return 15;
    case MascotDomainCategory.education:
      return 3;
    case MascotDomainCategory.bohemian:
      return isBurstPaced ? 7 : 16;
  }
}

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

  MascotDomainCategory get category {
    switch (id) {
      case 1:
      case 2:
      case 4:
      case 13:
        return MascotDomainCategory.nature;
      case 5:
      case 8:
      case 9:
      case 12:
        return MascotDomainCategory.humanities;
      case 6:
      case 10:
      case 11:
      case 14:
        return MascotDomainCategory.artPhysical;
      case 15:
        return MascotDomainCategory.service;
      case 3:
        return MascotDomainCategory.education;
      case 7:
      case 16:
        return MascotDomainCategory.bohemian;
      default:
        return MascotDomainCategory.nature;
    }
  }

  static const List<MascotSpeciesDefinition> all = [
    MascotSpeciesDefinition(
      id: 1,
      key: 'cat',
      name: '고양이',
      nickname: '삼순이',
      traitCode: '1100',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/1',
      persona: '기계·코드 파고드는 현실파. 평소엔 느긋하지만 마감 직전 폭주형.',
      signatureSuffix: '~냥',
      alarmDialogue: '일어날 시간이다냥! 햇빛 들어온다냥. 미션 후딱 풀고 다시 눕든가 하자냥!',
      reminderDialogue: '마감 1시간 전이다냥. 지금부터 초집중 모드 들어가면 에러 다 잡고 세이프다냥.',
      groomingDialogue: '골골골... 털 빗어주니 극락이다냥. 주머니에 털뭉치 찔러 넣어줬다냥~',
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
      persona: '데이터·구조화 선호. 일정 오차를 줄이는 분석형 플래너.',
      signatureSuffix: '~부엉',
      alarmDialogue: '오늘 일정의 오차 범위를 최소화할 시간이다부엉. 맑은 정신으로 시작해보자부엉.',
      reminderDialogue: '마감까지 잔여 시간 3시간. 현시점에서 중간 세이브와 점검을 권장한다부엉.',
      groomingDialogue: '깃털 결의 공기 저항이 줄어들었다부엉. 정돈 상태 매우 양호하다부엉.',
    ),
    MascotSpeciesDefinition(
      id: 3,
      key: 'turtle',
      name: '거북이',
      nickname: '부기',
      traitCode: '0000',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/3',
      persona: '조급함을 낮추는 페이스메이커 멘토. 느려도 방향이 맞으면 승리라는 타입.',
      signatureSuffix: '~부기',
      alarmDialogue: '천천히... 하지만 제시간에 일어나는 게 가장 안전한 법이다부기. 한 걸음씩 내딛자부기.',
      reminderDialogue: '마감 2시간 전이다부기. 조급해하지 말고 호흡을 가다듬으며 마침표를 찍어보자부기.',
      groomingDialogue: '등껍질 틈새까지 정성껏 쓸어주어 고맙다부기. 꾸준함이 모여 결실이 되는 법이다부기.',
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
      persona: '툴/체크리스트/자동화 사랑하는 실천형 메이커.',
      signatureSuffix: '~비버',
      alarmDialogue: '기상! 기상비버! 오늘의 체크리스트 세팅 끝났다비버! 얼른 미션 뚝딱 해치우자비버!',
      reminderDialogue: '과제 마감 2시간 전! 남은 항목 2개만 지우면 오늘 작업 끝이다비버!',
      groomingDialogue: '털이 착 가라앉아서 작업 효율 최고다비버! 뚝딱 모은 털뭉치 받아라비버!',
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
      persona: '느릿하지만 깊이 있는 통찰형. 읽고 쓰며 사고를 정제한다.',
      signatureSuffix: '~늘보',
      alarmDialogue: '일어날 시간... 이라오늘보... 서두를 것 없으니... 한 호흡 쉬고 시작하오...',
      reminderDialogue: '마감 1시간 전... 조용히 자판을 두드리면... 생각보다 문장이 술술 풀린다오늘보.',
      groomingDialogue: '천천히 쓸어주니... 머릿속 잡념이 사라진다오늘보... 여기 털뭉치요...',
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
      persona: '오감 힐링형. 조급함보다 회복과 리듬을 중시한다.',
      signatureSuffix: '~판다',
      alarmDialogue: '일어나자판다! 아침 밥 든든하게 먹어야 오늘 하루도 힘을 내는 법이다판다!',
      reminderDialogue: '과제 마감 2시간 전이다판다! 간식 하나 입에 물고 편안하게 작성해보자판다~',
      groomingDialogue: '배 통통 두드리며 빗질 받으니 천국이다판다! 보송한 털뭉치 챙겨가라판다~',
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
      persona: '도파민 폭발 즉흥형. 예측 불가 텐션으로 돌파한다.',
      signatureSuffix: '~찌',
      alarmDialogue: '일어나찌! 얼른 일어나찌! 해가 중천에 떴다찌! 미션 파바박 깨부수자찌!',
      reminderDialogue: '마감 1시간 전! 비상사태다찌! 지금부터 손가락 모터 돌리면 무조건 끝난다찌! 가자찌!',
      groomingDialogue: '간질간질 찌르르르! 쳇바퀴 100바퀴 돌릴 힘이 난다찌! 털뭉치 던지고 간다찌!',
    ),
    MascotSpeciesDefinition(
      id: 8,
      key: 'fox',
      name: '여우',
      nickname: '아랑',
      traitCode: '1101',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/8',
      persona: '핵심 맥락을 빠르게 짚는 위트형 전략가.',
      signatureSuffix: '~라구',
      alarmDialogue: '좋은 아침! 오늘 하루 흐름은 내가 딱 꿰고 있으니 걱정 말고 일어나라구!',
      reminderDialogue: '마감 2시간 전! 구구절절 쓸 거 없이 핵심 문장 딱 3개만 강조하면 끝이라구.',
      groomingDialogue: '풍성한 꼬리 관리는 내 자존심이라구. 감사의 뜻으로 반짝이는 털뭉치 투척!',
    ),
    MascotSpeciesDefinition(
      id: 9,
      key: 'squirrel',
      name: '다람쥐',
      nickname: '람이',
      traitCode: '0010',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/9',
      persona: '메모·기록·아카이빙 장인. 빠진 것을 잘 찾아낸다.',
      signatureSuffix: '~람쥐',
      alarmDialogue: '일어날 시간이에요람쥐. 어제 적어둔 메모 보면서 오늘 하루 차근차근 시작해요람쥐.',
      reminderDialogue: '과제 마감 3시간 전이에요람쥐. 빠진 출처나 오타 없는지 제가 한 번 훑어볼게요람쥐.',
      groomingDialogue: '털이 단정해졌어요람쥐! 볼 주머니에 소중히 모아둔 털뭉치 나눠드릴게요람쥐~',
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
      persona: '신체활동 기반 직진형. 몸을 쓰며 집중력을 올리는 타입.',
      signatureSuffix: '~멍',
      alarmDialogue: '기상이다멍! 해 떴다멍! 가볍게 몸 풀고 활기차게 출발해보자멍!',
      reminderDialogue: '마감 1시간 반 전이다멍! 으르렁! 지금 파바박 치고 나가서 끝내버리자멍!',
      groomingDialogue: '엉덩이 빗겨주는 거냐멍? 너무 좋다멍! 털 뿜뿜 털뭉치 대방출이다멍!',
    ),
    MascotSpeciesDefinition(
      id: 11,
      key: 'sealion',
      name: '바다사자',
      nickname: '바루',
      traitCode: '0100',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.burst,
      cognition: MascotCognition.logic,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/11',
      persona: '그루브/직관 중심. 규칙보다 유연한 흐름을 타는 타입.',
      signatureSuffix: '~물개',
      alarmDialogue: '물살을 가르듯 시원하게 일어날 시간이다물개. 오늘 리듬도 매끄럽게 타보자물개.',
      reminderDialogue: '과제 마감 2시간 전! 당황하지 말고 그루브 타듯 하나씩 마무리해보자물개.',
      groomingDialogue: '매끈한 털 결이 더 반짝인다물개. 보답으로 바다에서 건진 조개 같은 털뭉치 투척!',
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
      persona: '공지/정보 수집 + 팩트체크 특화 츤데레 정보통.',
      signatureSuffix: '~까악',
      alarmDialogue: '까악! 아침이다까악! 남들보다 반 박자 빨라야 꿀정보를 챙기는 법이다까악!',
      reminderDialogue: '과제 마감 1시간 전이다까악! 내가 찾아둔 자료 참고해서 마지막 마침표 찍어라까악!',
      groomingDialogue: '깃털 손질 안 해주면 날개 무거워진다까악! 특별히 내 깃털뭉치 하나 주마까악!',
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
      persona: '분해·조립·문제해결 손재주형. 막힌 설정을 끝내 푼다.',
      signatureSuffix: '~달',
      alarmDialogue: '기상 완료달! 차가운 물로 어푸어푸 세수하고 머리 회로 돌려보자달!',
      reminderDialogue: '마감 3시간 전달! 막힌 부분 있으면 내가 같이 봐줄 테니 일단 돌려보자달!',
      groomingDialogue: '손재주 좋은 내 털을 빗겨주다니 안목이 탁월하다달! 털뭉치 선물이다달~',
    ),
    MascotSpeciesDefinition(
      id: 14,
      key: 'rabbit',
      name: '토끼',
      nickname: '라비',
      traitCode: '0011',
      rhythm: MascotRhythm.day,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.active,
      assetBasePath: 'assets/images/mascots/14',
      persona: '민첩한 템포 조율형. 타이밍 감각으로 빠르게 끝낸다.',
      signatureSuffix: '~토',
      alarmDialogue: '기상토! 내 귀에 벌써 타이머 소리가 들린다토! 가볍게 깡총 튀어나올 시간이다토!',
      reminderDialogue: '마감 1시간 전토! 지금 템포 올려서 파바박 끝내고 자유를 누리자토!',
      groomingDialogue: '귀 뒤쪽 털까지 시원하게 빗겨줘서 고맙다토! 보송보송 솜사탕 털뭉치 받아라토!',
    ),
    MascotSpeciesDefinition(
      id: 15,
      key: 'koala',
      name: '코알라',
      nickname: '알라',
      traitCode: '1010',
      rhythm: MascotRhythm.night,
      execution: MascotExecution.plan,
      cognition: MascotCognition.text,
      energy: MascotEnergy.calm,
      assetBasePath: 'assets/images/mascots/15',
      persona: '정서적 케어 힐러. 자책을 낮추고 회복을 돕는 타입.',
      signatureSuffix: '~코',
      alarmDialogue: '일어날 시간이에코~ 심호흡 크게 한 번 하고 물 한잔 마시면서 천천히 움직이자코.',
      reminderDialogue: '과제 마감 2시간 전이에코. 너무 완벽하려 애쓰지 말고, 할 수 있는 만큼만 해도 충분하다코.',
      groomingDialogue: '털을 빗어주니 구름 위에 둥둥 뜬 기분이에코... 보송한 털뭉치 꼭 쥐여주겠다코~',
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
      persona: '태평낙천 무계획형. 실수해도 훌훌 털고 다시 가는 타입.',
      signatureSuffix: '~덕',
      alarmDialogue: '꽥! 일어날 시간이다덕! 대충 모자 쓰고 뛰어가면 세이프다덕!',
      reminderDialogue: '과제 마감 1시간 전이다덕! 막히는 건 일단 넘기고 제출부터 누르는 게 승자다덕!',
      groomingDialogue: '깃털이 가벼워져서 날아갈 것 같다덕! 노란 깃털뭉치 두고 간다덕~',
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
