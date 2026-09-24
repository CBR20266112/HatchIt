enum MascotStage { egg, hatched }

const _copyWithUnset = Object();

class MascotProfile {
  const MascotProfile({
    required this.id,
    required this.currentStage,
    required this.eggCrackDay,
    required this.speciesId,
    required this.equippedTool,
    required this.equippedHat,
    required this.expPlumBlossom,
    required this.curFurBalls,
    required this.curKeycaps,
    required this.furGrowthGauge,
    required this.rhythmScore,
    required this.executionScore,
    required this.cognitionScore,
    required this.energyScore,
    required this.natureScore,
    required this.humanitiesScore,
    required this.artPhysicalScore,
    required this.serviceScore,
    required this.educationScore,
    required this.bohemianScore,
    required this.burstPaceScore,
    required this.deepFocusScore,
    required this.lastPetTime,
    required this.lastFeedTime,
  });

  final int id;
  final MascotStage currentStage;
  final int eggCrackDay;
  final int? speciesId;
  final String? equippedTool;
  final String? equippedHat;
  final int expPlumBlossom;
  final int curFurBalls;
  final int curKeycaps;
  final int furGrowthGauge;
  final int rhythmScore;
  final int executionScore;
  final int cognitionScore;
  final int energyScore;
  final int natureScore;
  final int humanitiesScore;
  final int artPhysicalScore;
  final int serviceScore;
  final int educationScore;
  final int bohemianScore;
  final int burstPaceScore;
  final int deepFocusScore;
  final DateTime? lastPetTime;
  final DateTime? lastFeedTime;

  int get level => (expPlumBlossom ~/ 100) + 1;

  static const MascotProfile defaults = MascotProfile(
    id: 1,
    currentStage: MascotStage.egg,
    eggCrackDay: 0,
    speciesId: 1,
    equippedTool: null,
    equippedHat: null,
    expPlumBlossom: 0,
    curFurBalls: 0,
    curKeycaps: 0,
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
  );

  MascotProfile copyWith({
    int? id,
    MascotStage? currentStage,
    int? eggCrackDay,
    Object? speciesId = _copyWithUnset,
    Object? equippedTool = _copyWithUnset,
    Object? equippedHat = _copyWithUnset,
    int? expPlumBlossom,
    int? curFurBalls,
    int? curKeycaps,
    int? furGrowthGauge,
    int? rhythmScore,
    int? executionScore,
    int? cognitionScore,
    int? energyScore,
    int? natureScore,
    int? humanitiesScore,
    int? artPhysicalScore,
    int? serviceScore,
    int? educationScore,
    int? bohemianScore,
    int? burstPaceScore,
    int? deepFocusScore,
    Object? lastPetTime = _copyWithUnset,
    Object? lastFeedTime = _copyWithUnset,
  }) {
    return MascotProfile(
      id: id ?? this.id,
      currentStage: currentStage ?? this.currentStage,
      eggCrackDay: eggCrackDay ?? this.eggCrackDay,
      speciesId: speciesId == _copyWithUnset ? this.speciesId : speciesId as int?,
      equippedTool: equippedTool == _copyWithUnset
          ? this.equippedTool
          : equippedTool as String?,
      equippedHat: equippedHat == _copyWithUnset
          ? this.equippedHat
          : equippedHat as String?,
      expPlumBlossom: expPlumBlossom ?? this.expPlumBlossom,
      curFurBalls: curFurBalls ?? this.curFurBalls,
      curKeycaps: curKeycaps ?? this.curKeycaps,
      furGrowthGauge: furGrowthGauge ?? this.furGrowthGauge,
      rhythmScore: rhythmScore ?? this.rhythmScore,
      executionScore: executionScore ?? this.executionScore,
      cognitionScore: cognitionScore ?? this.cognitionScore,
      energyScore: energyScore ?? this.energyScore,
      natureScore: natureScore ?? this.natureScore,
      humanitiesScore: humanitiesScore ?? this.humanitiesScore,
      artPhysicalScore: artPhysicalScore ?? this.artPhysicalScore,
      serviceScore: serviceScore ?? this.serviceScore,
      educationScore: educationScore ?? this.educationScore,
      bohemianScore: bohemianScore ?? this.bohemianScore,
      burstPaceScore: burstPaceScore ?? this.burstPaceScore,
      deepFocusScore: deepFocusScore ?? this.deepFocusScore,
      lastPetTime: lastPetTime == _copyWithUnset
          ? this.lastPetTime
          : lastPetTime as DateTime?,
      lastFeedTime: lastFeedTime == _copyWithUnset
          ? this.lastFeedTime
          : lastFeedTime as DateTime?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'current_stage': _stageToDb(currentStage),
      'egg_crack_day': eggCrackDay,
      'species_id': speciesId,
      'equipped_tool': equippedTool,
      'equipped_hat': equippedHat,
      'exp_plum_blossom': expPlumBlossom,
      'cur_fur_balls': curFurBalls,
      'cur_keycaps': curKeycaps,
      'fur_growth_gauge': furGrowthGauge,
      'rhythm_score': rhythmScore,
      'execution_score': executionScore,
      'cognition_score': cognitionScore,
      'energy_score': energyScore,
      'nature_score': natureScore,
      'humanities_score': humanitiesScore,
      'art_physical_score': artPhysicalScore,
      'service_score': serviceScore,
      'education_score': educationScore,
      'bohemian_score': bohemianScore,
      'burst_pace_score': burstPaceScore,
      'deep_focus_score': deepFocusScore,
      'last_pet_time': lastPetTime?.toIso8601String(),
      'last_feed_time': lastFeedTime?.toIso8601String(),
    };
  }

  factory MascotProfile.fromMap(Map<String, Object?> map) {
    return MascotProfile(
      id: (map['id'] as int?) ?? 1,
      currentStage: _stageFromDb((map['current_stage'] as String?) ?? 'EGG'),
      eggCrackDay: (map['egg_crack_day'] as int?) ?? 0,
      speciesId: map['species_id'] as int?,
      equippedTool: map['equipped_tool'] as String?,
      equippedHat: map['equipped_hat'] as String?,
      expPlumBlossom: (map['exp_plum_blossom'] as int?) ?? 0,
      curFurBalls: (map['cur_fur_balls'] as int?) ?? 0,
      curKeycaps: (map['cur_keycaps'] as int?) ?? 0,
      furGrowthGauge: (map['fur_growth_gauge'] as int?) ?? 0,
      rhythmScore: (map['rhythm_score'] as int?) ?? 0,
      executionScore: (map['execution_score'] as int?) ?? 0,
      cognitionScore: (map['cognition_score'] as int?) ?? 0,
      energyScore: (map['energy_score'] as int?) ?? 0,
      natureScore: (map['nature_score'] as int?) ?? 0,
      humanitiesScore: (map['humanities_score'] as int?) ?? 0,
      artPhysicalScore: (map['art_physical_score'] as int?) ?? 0,
      serviceScore: (map['service_score'] as int?) ?? 0,
      educationScore: (map['education_score'] as int?) ?? 0,
      bohemianScore: (map['bohemian_score'] as int?) ?? 0,
      burstPaceScore: (map['burst_pace_score'] as int?) ?? 0,
      deepFocusScore: (map['deep_focus_score'] as int?) ?? 0,
      lastPetTime: DateTime.tryParse((map['last_pet_time'] as String?) ?? ''),
      lastFeedTime: DateTime.tryParse((map['last_feed_time'] as String?) ?? ''),
    );
  }

  static String _stageToDb(MascotStage stage) {
    switch (stage) {
      case MascotStage.egg:
        return 'EGG';
      case MascotStage.hatched:
        return 'MASCOT';
    }
  }

  static MascotStage _stageFromDb(String value) {
    switch (value) {
      case 'HATCHED':
      case 'MASCOT':
        return MascotStage.hatched;
      case 'EGG':
      default:
        return MascotStage.egg;
    }
  }
}
