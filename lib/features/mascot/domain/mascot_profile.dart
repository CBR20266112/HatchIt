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
      lastPetTime: DateTime.tryParse((map['last_pet_time'] as String?) ?? ''),
      lastFeedTime: DateTime.tryParse((map['last_feed_time'] as String?) ?? ''),
    );
  }

  static String _stageToDb(MascotStage stage) {
    switch (stage) {
      case MascotStage.egg:
        return 'EGG';
      case MascotStage.hatched:
        return 'HATCHED';
    }
  }

  static MascotStage _stageFromDb(String value) {
    switch (value) {
      case 'HATCHED':
        return MascotStage.hatched;
      case 'EGG':
      default:
        return MascotStage.egg;
    }
  }
}
