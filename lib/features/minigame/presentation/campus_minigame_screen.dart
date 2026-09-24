import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../mascot/presentation/mascot_controller.dart';

enum _ArcadeGame { keycap, stealthPhone, catCombo }

typedef _RewardFn = Future<void> Function({int exp, int furBalls, int keycaps});

const _arcadeMascotBase = 'assets/images/mascots/1';

Widget _buildArcadeMascotAsset({
  required List<String> candidates,
  double width = 88,
  double height = 88,
}) {
  Widget buildAt(int index) {
    if (index >= candidates.length) {
      return const Icon(Icons.pets_rounded, size: 72);
    }
    return Image.asset(
      '$_arcadeMascotBase/${candidates[index]}',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => buildAt(index + 1),
    );
  }

  return buildAt(0);
}

class CampusMiniGameScreen extends ConsumerWidget {
  const CampusMiniGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> openGame(_ArcadeGame game) async {
      switch (game) {
        case _ArcadeGame.keycap:
          await Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _KeycapGamePage(
                onReward: ({exp = 0, furBalls = 0, keycaps = 0}) async {
                  await ref
                      .read(mascotProfileProvider.notifier)
                      .grantMiniGameRewards(
                        exp: exp,
                        furBalls: furBalls,
                        keycaps: keycaps,
                      );
                },
              ),
            ),
          );
          return;
        case _ArcadeGame.stealthPhone:
          await Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _StealthPhoneGamePage(
                onReward: ({exp = 0, furBalls = 0, keycaps = 0}) async {
                  await ref
                      .read(mascotProfileProvider.notifier)
                      .grantMiniGameRewards(
                        exp: exp,
                        furBalls: furBalls,
                        keycaps: keycaps,
                      );
                },
              ),
            ),
          );
          return;
        case _ArcadeGame.catCombo:
          await Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _CatComboGamePage(
                onReward: ({exp = 0, furBalls = 0, keycaps = 0}) async {
                  await ref
                      .read(mascotProfileProvider.notifier)
                      .grantMiniGameRewards(
                        exp: exp,
                        furBalls: furBalls,
                        keycaps: keycaps,
                      );
                },
              ),
            ),
          );
          return;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        Text('캠퍼스 오락실', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(l10n.screenMiniGame),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _ArcadeShellCard(
              title: '수업 몰래 키캡 뽑기',
              subtitle: '탭/플릭 + 3% 희귀 키캡',
              icon: Icons.keyboard_outlined,
              color: const Color(0xFF5C6BC0),
              onTap: () => openGame(_ArcadeGame.keycap),
            ),
            _ArcadeShellCard(
              title: '교수님 몰래 폰 보기',
              subtitle: '롱터치 + 랜덤 경고 회피',
              icon: Icons.smartphone_outlined,
              color: const Color(0xFF26A69A),
              onTap: () => openGame(_ArcadeGame.stealthPhone),
            ),
            _ArcadeShellCard(
              title: '길고양이 궁디팡팡',
              subtitle: '3초 쓰다듬기 + 5초 연타',
              icon: Icons.pets_outlined,
              color: const Color(0xFFFFA726),
              onTap: () => openGame(_ArcadeGame.catCombo),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArcadeShellCard extends StatelessWidget {
  const _ArcadeShellCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withValues(alpha: 0.18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  '탭해서 시작',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child});

  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.98 : 1,
        child: widget.child,
      ),
    );
  }
}

class _KeycapGamePage extends StatefulWidget {
  const _KeycapGamePage({required this.onReward});

  final _RewardFn onReward;

  @override
  State<_KeycapGamePage> createState() => _KeycapGamePageState();
}

class _KeycapGamePageState extends State<_KeycapGamePage> {
  final Random _random = Random();
  late List<_KeycapTileState> _tiles;
  int _furSession = 0;
  int _keycapSession = 0;
  bool _showKeycapBite = false;

  @override
  void initState() {
    super.initState();
    _tiles = List<_KeycapTileState>.generate(15, (_) => _KeycapTileState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수업 몰래 키캡 뽑기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번 판 누적: 털뭉치 +$_furSession · 희귀 키캡 +$_keycapSession'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _buildArcadeMascotAsset(
                      candidates: _showKeycapBite
                          ? const ['keycap_bite.png', 'action_typing.png']
                          : const ['typing.png', 'action_typing.png'],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _showKeycapBite
                            ? '획득 성공! 키캡 물기 연출'
                            : '탭/플릭으로 키캡을 뽑아보세요.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _tiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final tile = _tiles[index];
                  return GestureDetector(
                    onTap: () => _popKeycap(index, flick: false),
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() > 500) {
                        _popKeycap(index, flick: true);
                      }
                    },
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 240),
                      offset: tile.offset,
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 240),
                        turns: tile.turns,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: tile.detached ? 0.18 : 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: tile.detached
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                            ),
                            child: Center(
                              child: Text(
                                tile.detached ? '💨' : '⌨️',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _resetBoard,
              icon: const Icon(Icons.refresh),
              label: const Text('키캡 재장착'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _popKeycap(int index, {required bool flick}) async {
    final tile = _tiles[index];
    if (tile.detached) {
      return;
    }

    HapticFeedback.selectionClick();

    final fur = flick ? 2 + _random.nextInt(3) : 1 + _random.nextInt(2);
    final exp = flick ? 2 : 1;
    final rareDrop = _random.nextDouble() < 0.03;

    setState(() {
      tile.detached = true;
      tile.offset = Offset(
        (_random.nextDouble() - 0.5) * 2.4,
        -0.8 - _random.nextDouble() * 0.8,
      );
      tile.turns = (_random.nextDouble() - 0.5) * 0.6;
      _furSession += fur;
      _showKeycapBite = true;
      if (rareDrop) {
        _keycapSession += 1;
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showKeycapBite = false;
      });
    });

    await widget.onReward(exp: exp, furBalls: fur, keycaps: rareDrop ? 1 : 0);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rareDrop ? '희귀 키캡 드랍! (3%) 키캡 +1, 털뭉치 +$fur' : '키캡 분리 성공! 털뭉치 +$fur',
        ),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _resetBoard() {
    setState(() {
      _tiles = List<_KeycapTileState>.generate(15, (_) => _KeycapTileState());
      _furSession = 0;
      _keycapSession = 0;
      _showKeycapBite = false;
    });
  }
}

class _KeycapTileState {
  bool detached = false;
  Offset offset = Offset.zero;
  double turns = 0;
}

class _StealthPhoneGamePage extends StatefulWidget {
  const _StealthPhoneGamePage({required this.onReward});

  final _RewardFn onReward;

  @override
  State<_StealthPhoneGamePage> createState() => _StealthPhoneGamePageState();
}

class _StealthPhoneGamePageState extends State<_StealthPhoneGamePage> {
  final Random _random = Random();

  bool _isHolding = false;
  bool _warning = false;
  bool _professorWatching = false;
  double _gauge = 0;
  int _score = 0;

  Timer? _gaugeTimer;
  Timer? _phaseTimer;
  Timer? _watchTimer;

  @override
  void initState() {
    super.initState();
    _scheduleProfessorLook();
  }

  @override
  void dispose() {
    _gaugeTimer?.cancel();
    _phaseTimer?.cancel();
    _watchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('교수님 몰래 폰 보기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _professorWatching
                      ? '👨‍🏫 뒤돌아봄!'
                      : _warning
                      ? '❗곧 뒤돌아봄'
                      : '😴 판서 중',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text('점수 $_score'),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _buildArcadeMascotAsset(
                      candidates: _professorWatching || _warning
                          ? const ['stealth_alert.png', 'expr_surprised.png']
                          : _isHolding
                          ? const ['typing.png', 'action_typing.png']
                          : const ['idle.png', 'idle_variant.png'],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _professorWatching || _warning
                            ? '경고 발동! 손 떼고 가만히!'
                            : _isHolding
                            ? '폰 보는 중: 타이핑 모드'
                            : '잠잠한 타이밍. 길게 눌러 점수 쌓기',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LinearProgressIndicator(value: _gauge),
            const SizedBox(height: 8),
            Text('스크롤 게이지 ${(100 * _gauge).toStringAsFixed(0)}%'),
            const SizedBox(height: 18),
            Expanded(
              child: GestureDetector(
                onLongPressStart: (_) => _startHolding(),
                onLongPressEnd: (_) => _stopHolding(),
                onLongPressCancel: _stopHolding,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: _professorWatching
                        ? Colors.red.withValues(alpha: 0.18)
                        : Theme.of(context).colorScheme.secondaryContainer,
                    border: Border.all(
                      color: _warning ? Colors.orange : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isHolding ? '📱 몰래 스크롤 중...' : '여기를 길게 눌러 몰래 폰 보기',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('규칙: 2~5초 랜덤 주기로 경고(!) 후 교수님이 뒤를 봅니다. 그때 손 떼고 있어야 안전!'),
          ],
        ),
      ),
    );
  }

  void _startHolding() {
    _isHolding = true;
    _gaugeTimer ??= Timer.periodic(const Duration(milliseconds: 120), (
      _,
    ) async {
      if (!mounted || !_isHolding || _professorWatching) {
        return;
      }

      setState(() {
        _gauge = (_gauge + 0.02).clamp(0, 1);
        _score += 1;
      });

      if (_score % 5 == 0) {
        await widget.onReward(exp: 1, furBalls: 1);
      }
    });
  }

  void _stopHolding() {
    _isHolding = false;
  }

  void _scheduleProfessorLook() {
    final waitSeconds = 2 + _random.nextInt(4);
    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(seconds: waitSeconds), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _warning = true;
      });
      HapticFeedback.mediumImpact();

      _watchTimer?.cancel();
      _watchTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) {
          return;
        }

        setState(() {
          _warning = false;
          _professorWatching = true;
        });

        if (_isHolding) {
          _caughtByProfessor();
          return;
        }

        Timer(const Duration(milliseconds: 800), () {
          if (!mounted) {
            return;
          }
          setState(() {
            _professorWatching = false;
          });
          _scheduleProfessorLook();
        });
      });
    });
  }

  void _caughtByProfessor() {
    _isHolding = false;
    setState(() {
      _gauge = (_gauge - 0.35).clamp(0, 1);
      _score = max(0, _score - 8);
      _professorWatching = false;
      _warning = false;
    });

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('걸렸다! 게이지/점수 차감 😵')));

    _scheduleProfessorLook();
  }
}

enum _CatPhase { trust, frenzy, done }

class _CatComboGamePage extends StatefulWidget {
  const _CatComboGamePage({required this.onReward});

  final _RewardFn onReward;

  @override
  State<_CatComboGamePage> createState() => _CatComboGamePageState();
}

class _CatComboGamePageState extends State<_CatComboGamePage> {
  _CatPhase _phase = _CatPhase.trust;
  double _trust = 0;
  int _leftSeconds = 5;
  int _tapCount = 0;
  Timer? _frenzyTimer;
  Timer? _flushTimer;
  Timer? _trustTimer;
  int _pendingFur = 0;
  bool _isRubbing = false;

  @override
  void initState() {
    super.initState();
    _flushTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _flushPendingRewards();
    });
  }

  @override
  void dispose() {
    _frenzyTimer?.cancel();
    _flushTimer?.cancel();
    _trustTimer?.cancel();
    _flushPendingRewards();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('길고양이 궁디팡팡')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _buildArcadeMascotAsset(
                      candidates: _phase == _CatPhase.frenzy
                          ? const ['butt_up.png', 'view_back.png']
                          : _phase == _CatPhase.done
                          ? const ['mission_clear.png', 'jump.png']
                          : const ['pet_snuggle.png', 'exp_touched_alt.png'],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _phase == _CatPhase.frenzy
                            ? '2단계 진입! 고양이가 뒤돌았어요. 궁디팡팡 연타!'
                            : _phase == _CatPhase.done
                            ? '게임 완료!'
                            : '1단계 쓰다듬기로 신뢰를 쌓는 중',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_phase == _CatPhase.trust) ...[
              const Text('1단계: 얼굴/턱을 부드럽게 드래그해서 호감도 100% 만들기 (3초 내외)'),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _trust),
              const SizedBox(height: 8),
              Text('호감도 ${(_trust * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 14),
              Expanded(
                child: GestureDetector(
                  onPanStart: (_) => _startTrustRub(),
                  onPanUpdate: _onTrustDrag,
                  onPanEnd: (_) => _stopTrustRub(),
                  onPanCancel: _stopTrustRub,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.orange.withValues(alpha: 0.12),
                    ),
                    child: const Center(
                      child: Text(
                        '🐱\n얼굴/턱 드래그',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (_phase == _CatPhase.frenzy) ...[
              Text(
                '2단계: 5초 연타! 남은 시간: $_leftSeconds초',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('연타 수: $_tapCount회'),
              const SizedBox(height: 14),
              Expanded(
                child: GestureDetector(
                  onTap: _onFrenzyTap,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.brown.withValues(alpha: 0.14),
                    ),
                    child: const Center(
                      child: Text(
                        '🐈\n엉덩이 영역 연타!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text('정산 완료!'),
              const SizedBox(height: 8),
              Text('총 연타: $_tapCount회 / 획득 털뭉치: +$_tapCount'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onTrustDrag(DragUpdateDetails details) {
    if (_phase != _CatPhase.trust) {
      return;
    }

    HapticFeedback.selectionClick();
  }

  void _startTrustRub() {
    if (_phase != _CatPhase.trust || _isRubbing) {
      return;
    }

    _isRubbing = true;
    _trustTimer?.cancel();
    _trustTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isRubbing || _phase != _CatPhase.trust) {
        timer.cancel();
        return;
      }

      setState(() {
        _trust = (_trust + (1 / 30)).clamp(0, 1);
      });

      if (_trust >= 1) {
        timer.cancel();
        _startFrenzy();
      }
    });
  }

  void _stopTrustRub() {
    _isRubbing = false;
    _trustTimer?.cancel();
  }

  void _startFrenzy() {
    _stopTrustRub();
    setState(() {
      _phase = _CatPhase.frenzy;
      _leftSeconds = 5;
      _tapCount = 0;
    });

    _frenzyTimer?.cancel();
    _frenzyTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_leftSeconds <= 1) {
        timer.cancel();
        await _flushPendingRewards();
        await widget.onReward(exp: 5);
        if (!mounted) {
          return;
        }
        setState(() {
          _leftSeconds = 0;
          _phase = _CatPhase.done;
        });
        return;
      }

      setState(() {
        _leftSeconds -= 1;
      });
    });
  }

  void _onFrenzyTap() {
    if (_phase != _CatPhase.frenzy) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _tapCount += 1;
      _pendingFur += 1;
    });
  }

  Future<void> _flushPendingRewards() async {
    if (_pendingFur <= 0) {
      return;
    }

    final reward = _pendingFur;
    _pendingFur = 0;
    await widget.onReward(furBalls: reward);
  }
}
