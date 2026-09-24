import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
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

enum PersonalityAxis { rhythm, execution, cognition, energy }

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
        now.difference(current.lastPetTime!).inMinutes < 10) {
      return false;
    }

    final nextGauge = (current.furGrowthGauge + 15).clamp(0, 100);
    final next = current.copyWith(lastPetTime: now, furGrowthGauge: nextGauge);

    await _dao.saveProfile(next);
    state = AsyncData(next);
    return true;
  }

  Future<bool> feed() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final now = DateTime.now();

    if (current.lastFeedTime != null &&
        now.difference(current.lastFeedTime!).inMinutes < 120) {
      return false;
    }

    final nextGauge = (current.furGrowthGauge + 35).clamp(0, 100);
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
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
  }

  Future<void> submitDailyEggAnswer({
    required PersonalityAxis axis,
    required bool choosePositive,
  }) async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    if (current.currentStage != MascotStage.egg) {
      return;
    }

    var rhythmScore = current.rhythmScore;
    var executionScore = current.executionScore;
    var cognitionScore = current.cognitionScore;
    var energyScore = current.energyScore;

    switch (axis) {
      case PersonalityAxis.rhythm:
        if (choosePositive) {
          rhythmScore += 1;
        }
        break;
      case PersonalityAxis.execution:
        if (choosePositive) {
          executionScore += 1;
        }
        break;
      case PersonalityAxis.cognition:
        if (choosePositive) {
          cognitionScore += 1;
        }
        break;
      case PersonalityAxis.energy:
        if (choosePositive) {
          energyScore += 1;
        }
        break;
    }

    final nextCrackDay = (current.eggCrackDay + 1).clamp(0, 7);
    var next = current.copyWith(
      eggCrackDay: nextCrackDay,
      rhythmScore: rhythmScore,
      executionScore: executionScore,
      cognitionScore: cognitionScore,
      energyScore: energyScore,
      expPlumBlossom: current.expPlumBlossom + 20,
    );

    if (nextCrackDay >= 7) {
      final speciesId = MascotSpeciesDefinition.calculateSpeciesId(
        isNight: rhythmScore >= 2,
        isBurst: executionScore >= 2,
        isText: cognitionScore >= 2,
        isActive: energyScore >= 2,
      );
      next = next.copyWith(
        currentStage: MascotStage.hatched,
        speciesId: speciesId,
      );
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
    final next = current.copyWith(
      expPlumBlossom: current.expPlumBlossom + exp,
      curFurBalls: current.curFurBalls + furBalls,
      curKeycaps: current.curKeycaps + keycaps,
    );

    await _dao.saveProfile(next);
    state = AsyncData(next);
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

  Future<void> developerResetCooldowns() async {
    final current = state.valueOrNull ?? await _dao.getProfile();
    final next = current.copyWith(lastPetTime: null, lastFeedTime: null);

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
