import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../daily_records/presentation/daily_record_controller.dart';
import '../data/mascot_profile_dao.dart';
import '../domain/mascot_profile.dart';
import '../domain/mascot_species.dart';

final mascotProfileDaoProvider = Provider<MascotProfileDao>((ref) {
  return MascotProfileDao(ref.watch(appDatabaseProvider));
});

final mascotProfileProvider =
    AsyncNotifierProvider<MascotProfileNotifier, MascotProfile>(
      MascotProfileNotifier.new,
    );

class AdaptiveEggAnswerPayload {
  const AdaptiveEggAnswerPayload({
    this.natureDelta = 0,
    this.humanitiesDelta = 0,
    this.artPhysicalDelta = 0,
    this.serviceDelta = 0,
    this.educationDelta = 0,
    this.bohemianDelta = 0,
    this.burstPaceDelta = 0,
    this.deepFocusDelta = 0,
  });

  final int natureDelta;
  final int humanitiesDelta;
  final int artPhysicalDelta;
  final int serviceDelta;
  final int educationDelta;
  final int bohemianDelta;
  final int burstPaceDelta;
  final int deepFocusDelta;
}

class MascotProfileNotifier extends AsyncNotifier<MascotProfile> {
  MascotProfileDao get _dao => ref.read(mascotProfileDaoProvider);

  @override
  Future<MascotProfile> build() async {
    return _dao.getProfile();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _dao.getProfile());
  }

  Future<bool> pet() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final now = DateTime.now();

    if (current.lastPetTime != null &&
        now.difference(current.lastPetTime!).inMinutes < 60) {
      return false;
    }

    final nextGauge = (current.furGrowthGauge + 4).clamp(0, 100);
    final next = current.copyWith(lastPetTime: now, furGrowthGauge: nextGauge);

    await _dao.saveProfile(next);
    state = AsyncData(next);
    return true;
  }

  Future<bool> feed() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final now = DateTime.now();

    if (current.lastFeedTime != null &&
        now.difference(current.lastFeedTime!).inMinutes < 360) {
      return false;
    }

    final nextGauge = (current.furGrowthGauge + 8).clamp(0, 100);
    final next = current.copyWith(lastFeedTime: now, furGrowthGauge: nextGauge);

    await _dao.saveProfile(next);
    state = AsyncData(next);
    return true;
  }

  Future<void> rewardFromDailyRecord() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final nextCrackDay = current.currentStage == MascotStage.egg
        ? (current.eggCrackDay + 1).clamp(0, 7)
        : current.eggCrackDay;

    final nextStage = nextCrackDay >= 7
        ? MascotStage.hatched
        : current.currentStage;

    final next = current.copyWith(
      expPlumBlossom: current.expPlumBlossom + 20,
      eggCrackDay: nextCrackDay,
      currentStage: nextStage,
      furGrowthGauge: (current.furGrowthGauge + 6).clamp(0, 100),
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> submitDailyEggAnswer({
    required AdaptiveEggAnswerPayload payload,
  }) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    if (current.currentStage != MascotStage.egg) {
      return;
    }

    final nextCrackDay = (current.eggCrackDay + 1).clamp(0, 7);
    var next = current.copyWith(
      eggCrackDay: nextCrackDay,
      natureScore: current.natureScore + payload.natureDelta,
      humanitiesScore: current.humanitiesScore + payload.humanitiesDelta,
      artPhysicalScore: current.artPhysicalScore + payload.artPhysicalDelta,
      serviceScore: current.serviceScore + payload.serviceDelta,
      educationScore: current.educationScore + payload.educationDelta,
      bohemianScore: current.bohemianScore + payload.bohemianDelta,
      burstPaceScore: current.burstPaceScore + payload.burstPaceDelta,
      deepFocusScore: current.deepFocusScore + payload.deepFocusDelta,
      expPlumBlossom: current.expPlumBlossom + 20,
      furGrowthGauge: (current.furGrowthGauge + 6).clamp(0, 100),
    );

    if (nextCrackDay >= 7) {
      final scoreByCategory = <MascotDomainCategory, int>{
        MascotDomainCategory.nature: next.natureScore,
        MascotDomainCategory.humanities: next.humanitiesScore,
        MascotDomainCategory.artPhysical: next.artPhysicalScore,
        MascotDomainCategory.service: next.serviceScore,
        MascotDomainCategory.education: next.educationScore,
        MascotDomainCategory.bohemian: next.bohemianScore,
      };

      final dominantCategory = scoreByCategory.entries.reduce((a, b) {
        return a.value >= b.value ? a : b;
      }).key;

      final speciesId = calculateAdaptiveMascotId(
        dominantCategory: dominantCategory,
        isBurstPaced: next.burstPaceScore >= 2,
        isDeepFocus: next.deepFocusScore >= 2,
      );

      next = next.copyWith(currentStage: MascotStage.hatched, speciesId: speciesId);
    }

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<int> completeBrushing({required int strokeCount}) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final reward = (strokeCount ~/ 8).clamp(1, 25);

    final next = current.copyWith(
      furGrowthGauge: 0,
      curFurBalls: current.curFurBalls + reward,
      expPlumBlossom: current.expPlumBlossom + 5,
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
    return reward;
  }

  Future<void> grantMiniGameRewards({
    int exp = 0,
    int furBalls = 0,
    int keycaps = 0,
  }) async {
    if (exp == 0 && furBalls == 0 && keycaps == 0) {
      return;
    }

    final current = state.valueOrNull ?? await _dao.getProfile();
    final miniGameGaugeBonus =
        ((exp ~/ 5) + (furBalls ~/ 12) + (keycaps * 2)).clamp(0, 3);
    final next = current.copyWith(
      expPlumBlossom: current.expPlumBlossom + exp,
      curFurBalls: current.curFurBalls + furBalls,
      curKeycaps: current.curKeycaps + keycaps,
      furGrowthGauge: (current.furGrowthGauge + miniGameGaugeBonus).clamp(0, 100),
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> rewardFromAlarmDismiss() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final next = current.copyWith(
      expPlumBlossom: current.expPlumBlossom + 3,
      furGrowthGauge: (current.furGrowthGauge + 5).clamp(0, 100),
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> rewardFromMissionResult({required bool success}) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final next = current.copyWith(
      expPlumBlossom: current.expPlumBlossom + (success ? 8 : 3),
      furGrowthGauge: (current.furGrowthGauge + (success ? 10 : 4)).clamp(0, 100),
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> rewardFromMiniGameSession() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final next = current.copyWith(
      expPlumBlossom: current.expPlumBlossom + 2,
      furGrowthGauge: (current.furGrowthGauge + 4).clamp(0, 100),
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  bool _isProcessing = false;

  /// 개발자 치트: 부화 일자 +1일 진행 (클릭당 정확히 +1일 단일 갱신 및 연쇄 중복 가산 방지)
  Future<void> developerAdvanceEggDay({int fallbackSpeciesId = 1}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final current = state.valueOrNull ?? await _dao.getProfile();
      final currentDay = current.eggCrackDay;
      final nextDay = (currentDay + 1).clamp(0, 7);
      final shouldHatch = nextDay >= 7;

      final next = current.copyWith(
        eggCrackDay: nextDay,
        currentStage: shouldHatch ? MascotStage.hatched : current.currentStage,
        speciesId: shouldHatch
            ? (current.speciesId ?? fallbackSpeciesId)
            : current.speciesId,
      );

      // DB 기록을 먼저 삭제한 후 State 갱신
      // (순서가 반대이면 ref.listen이 state 변경을 감지해 _syncTodayQuestionStatus를
      //  호출할 때 아직 DB에 오늘 기록이 남아있어 _isTodayQuestionAnswered=true로
      //  되돌아가는 race condition 발생)
      await ref.read(dailyRecordControllerProvider).clearAllRecords();

      // DB와 State를 일괄 업데이트 (중복 가산 방지)
      if (shouldHatch) {
        await _dao.saveProfile(next);
      } else {
        await _dao.updateEggCrackDay(nextDay);
      }
      state = AsyncData(next);
    } catch (e) {
      debugPrint('[developerAdvanceEggDay] error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> developerInstantHatch({int fallbackSpeciesId = 1}) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final next = current.copyWith(
      currentStage: MascotStage.hatched,
      eggCrackDay: 7,
      speciesId: current.speciesId ?? fallbackSpeciesId,
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  /// 개발자 치트: 마스코트 상호작용(밥주기, 쓰다듬기, 빗질) 쿨타임을 DateTime(2000)으로 리셋
  Future<void> developerResetCooldowns() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final past = DateTime(2000);
    final next = current.copyWith(
      lastPetTime: past,
      lastFeedTime: past,
      furGrowthGauge: 100, // 빗질 즉시 수행 가능하도록 게이지 완충
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> resetForAppDataClear() async {
    await _dao.resetProfile();
    await refresh();
  }

  Future<void> developerResetToEgg({bool resetEconomy = false}) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final next = current.copyWith(
      currentStage: MascotStage.egg,
      eggCrackDay: 0,
      speciesId: null,
      equippedTool: null,
      equippedHat: null,
      furGrowthGauge: 0,
      rhythmScore: 0,
      executionScore: 0,
      cognitionScore: 0,
      energyScore: 0,
      natureScore: 0,
      humanitiesScore: 0,
      artPhysicalScore: 0,
      serviceScore: 0,
      educationScore: 0,
      bohemianScore: 0,
      burstPaceScore: 0,
      deepFocusScore: 0,
      lastPetTime: null,
      lastFeedTime: null,
      expPlumBlossom: resetEconomy ? 0 : current.expPlumBlossom,
      curFurBalls: resetEconomy ? 0 : current.curFurBalls,
      curKeycaps: resetEconomy ? 0 : current.curKeycaps,
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> developerSetSpecies(
    int speciesId, {
    bool hatchIfEgg = false,
  }) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final shouldHatch = hatchIfEgg && current.currentStage == MascotStage.egg;
    final next = current.copyWith(
      speciesId: speciesId,
      currentStage: shouldHatch ? MascotStage.hatched : current.currentStage,
      eggCrackDay: shouldHatch ? 7 : current.eggCrackDay,
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }
}
