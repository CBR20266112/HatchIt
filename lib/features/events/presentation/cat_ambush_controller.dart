import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatAmbushState {
  const CatAmbushState({
    required this.isActive,
    required this.eventId,
    required this.totalSpawns,
    required this.lastSpawnAt,
    required this.lastResult,
  });

  const CatAmbushState.initial()
      : isActive = false,
        eventId = 0,
        totalSpawns = 0,
        lastSpawnAt = null,
        lastResult = null;

  final bool isActive;
  final int eventId;
  final int totalSpawns;
  final DateTime? lastSpawnAt;
  final String? lastResult;

  CatAmbushState copyWith({
    bool? isActive,
    int? eventId,
    int? totalSpawns,
    DateTime? lastSpawnAt,
    String? lastResult,
  }) {
    return CatAmbushState(
      isActive: isActive ?? this.isActive,
      eventId: eventId ?? this.eventId,
      totalSpawns: totalSpawns ?? this.totalSpawns,
      lastSpawnAt: lastSpawnAt ?? this.lastSpawnAt,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

final catAmbushControllerProvider =
    StateNotifierProvider<CatAmbushController, CatAmbushState>((ref) {
  return CatAmbushController();
});

class CatAmbushController extends StateNotifier<CatAmbushState> {
  CatAmbushController() : super(const CatAmbushState.initial());

  final _random = Random();
  Timer? _timer;

  void start() {
    if (_timer != null) {
      return;
    }

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _rollSpawn();
    });
  }

  void _rollSpawn() {
    if (state.isActive) {
      return;
    }

    final hit = _random.nextDouble() < 0.005;
    if (!hit) {
      return;
    }

    state = state.copyWith(
      isActive: true,
      eventId: state.eventId + 1,
      totalSpawns: state.totalSpawns + 1,
      lastSpawnAt: DateTime.now(),
      lastResult: null,
    );
  }

  void resolve({required bool success, required int taps}) {
    state = state.copyWith(
      isActive: false,
      lastResult: success ? '성공(궁디팡팡 $taps회)' : '실패(궁디팡팡 $taps회)',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
