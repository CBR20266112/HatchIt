import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../daily_records/domain/daily_record.dart';
import '../../daily_records/presentation/daily_record_controller.dart';
import '../domain/mascot_profile.dart';
import '../domain/mascot_species.dart';
import 'mascot_controller.dart';

class MascotHubScreen extends ConsumerStatefulWidget {
  const MascotHubScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<MascotHubScreen> createState() => _MascotHubScreenState();
}

class _MascotHubScreenState extends ConsumerState<MascotHubScreen> {
  Timer? _uiTicker;
  DateTime _now = DateTime.now();
  final List<_FxBurst> _fxBursts = [];

  @override
  void initState() {
    super.initState();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyQuestionPrompt();
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileValue = ref.watch(mascotProfileProvider);

    return profileValue.when(
      data: (profile) {
        final petRemain = _petCooldownRemaining(profile);
        final feedRemain = _feedCooldownRemaining(profile);
        final canBrush = profile.furGrowthGauge >= 100;
        final palette =
            Theme.of(context).extension<MascotThemePalette>() ??
            MascotThemePalette.fromSpeciesId(null);

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '비서실',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.edit_note_rounded),
                          label: const Text('오늘의 한 줄 문답'),
                          onPressed: _openTodayQuestion,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.settings_rounded),
                          label: const Text('설정'),
                          onPressed: widget.onOpenSettings,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFloatingCurrencyBar(profile, palette),
                const SizedBox(height: 14),
                _buildMascotShowcase(
                  profile: profile,
                  l10n: l10n,
                  canBrush: canBrush,
                  palette: palette,
                ),
                const SizedBox(height: 14),
                _buildGaugeCard(profile),
                const SizedBox(height: 10),
                _buildBottomControls(
                  profile: profile,
                  petRemain: petRemain,
                  feedRemain: feedRemain,
                  canBrush: canBrush,
                  palette: palette,
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: _fxBursts
                      .map(
                        (fx) => Align(
                          alignment: fx.alignment,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(fx.id),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, -28 * value),
                                child: Opacity(
                                  opacity: 1 - value,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(fx.icon, color: fx.color, size: 26),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('비서 허브 로드 실패: $error')),
    );
  }

  Widget _buildFloatingCurrencyBar(
    MascotProfile profile,
    MascotThemePalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerLowest,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 8,
        spacing: 8,
        children: [
          _pillChip(
            'Plum Blossom EXP ${profile.expPlumBlossom}',
            Icons.local_florist_outlined,
            palette.primary,
          ),
          _pillChip(
            'Fur Balls ${profile.curFurBalls}',
            Icons.blur_circular_outlined,
            palette.secondary,
          ),
          _pillChip(
            'Keycaps ${profile.curKeycaps}',
            Icons.keyboard_alt_outlined,
            palette.accent,
          ),
        ],
      ),
    );
  }

  Widget _pillChip(String text, IconData icon, Color color) {
    final isLight = ThemeData.estimateBrightnessForColor(color) ==
        Brightness.light;
    final foreground = isLight ? const Color(0xFF2A2A2A) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotShowcase({
    required MascotProfile profile,
    required AppLocalizations l10n,
    required bool canBrush,
    required MascotThemePalette palette,
  }) {
    final speaking = profile.currentStage == MascotStage.egg
        ? '알이 깨지는 중... 오늘도 한 걸음씩!'
        : '오늘도 집중 모드로 같이 달려요 ✨';

    final assetPath = _resolveMascotAssetPath(profile, canBrush: canBrush);
    final isEgg = profile.currentStage == MascotStage.egg;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.7),
            Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(speaking),
          ),
          const SizedBox(height: 14),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 34,
                  spreadRadius: 7,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                assetPath,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  if (isEgg) {
                    return CustomPaint(
                      size: const Size(150, 180),
                      painter: _EggPainter(crackDay: profile.eggCrackDay),
                    );
                  }
                  return _buildMascotFallback(
                    icon: Icons.pets_rounded,
                    size: 200,
                    subtitle: '삼순이 준비 중',
                    palette: palette,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard(MascotProfile profile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '털 성장 게이지',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: profile.furGrowthGauge / 100),
            const SizedBox(height: 6),
            Text(
              '${profile.furGrowthGauge}% / 100%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls({
    required MascotProfile profile,
    required Duration petRemain,
    required Duration feedRemain,
    required bool canBrush,
    required MascotThemePalette palette,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: petRemain == Duration.zero
                        ? () => _onPet(palette)
                        : null,
                    icon: const Icon(Icons.pan_tool_alt_outlined),
                    label: Text(
                      petRemain == Duration.zero
                          ? '쓰다듬기'
                          : '쿨타임 ${_formatDuration(petRemain)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: feedRemain == Duration.zero
                        ? () => _onFeed(palette)
                        : null,
                    icon: const Icon(Icons.ramen_dining),
                    label: Text(
                      feedRemain == Duration.zero
                          ? '밥주기'
                          : '쿨타임 ${_formatDuration(feedRemain)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: canBrush ? _startBrushingModal : null,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(
                      canBrush ? '빗질하기' : '${profile.furGrowthGauge}%',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!canBrush)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '빗질은 게이지 100%에서만 가능해요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _resolveMascotAssetPath(
    MascotProfile profile, {
    required bool canBrush,
  }) {
    final species = MascotSpeciesDefinition.byId(profile.speciesId ?? 1);
    final base = species.assetBasePath;

    if (profile.currentStage == MascotStage.egg) {
      final eggStage = profile.eggCrackDay.clamp(0, 7);
      return '$base/egg_$eggStage.png';
    }

    if (canBrush) {
      return '$base/grooming.png';
    }
    return '$base/idle.png';
  }

  Widget _buildMascotFallback({
    required IconData icon,
    required double size,
    required String subtitle,
    required MascotThemePalette palette,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                palette.secondary.withValues(alpha: 0.96),
                palette.accent.withValues(alpha: 0.28),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.42, color: palette.primary),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  Future<void> _onPet(MascotThemePalette palette) async {
    final ok = await ref.read(mascotProfileProvider.notifier).pet();
    if (!mounted) {
      return;
    }

    if (ok) {
      _spawnBurst(icon: Icons.favorite, color: palette.emotionHot, count: 8);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쓰다듬기 성공! 게이지 +15% (쿨타임 10분)')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 쿨타임이에요. 잠깐 쉬었다 다시 눌러주세요.')),
      );
    }
  }

  Future<void> _onFeed(MascotThemePalette palette) async {
    final ok = await ref.read(mascotProfileProvider.notifier).feed();
    if (!mounted) {
      return;
    }

    if (ok) {
      _spawnBurst(
        icon: Icons.rice_bowl_rounded,
        color: palette.accent,
        count: 9,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('밥주기 성공! 게이지 +35% (쿨타임 2시간)')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('밥주기는 2시간 쿨타임입니다.')));
    }
  }

  Future<void> _startBrushingModal() async {
    final strokeCount = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BrushingMissionDialog(),
    );

    if (strokeCount == null || !mounted) {
      return;
    }

    final reward = await ref
        .read(mascotProfileProvider.notifier)
        .completeBrushing(strokeCount: strokeCount);

    if (!mounted) {
      return;
    }

    final palette =
        Theme.of(context).extension<MascotThemePalette>() ??
        MascotThemePalette.fromSpeciesId(null);
    _spawnBurst(icon: Icons.blur_circular, color: palette.primary, count: 12);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('빗질 종료! 털뭉치 +$reward, 게이지 0% 리셋 완료')),
    );
  }

  void _spawnBurst({
    required IconData icon,
    required Color color,
    int count = 7,
  }) {
    final random = Random();
    final now = DateTime.now().microsecondsSinceEpoch;

    setState(() {
      for (var i = 0; i < count; i++) {
        final x = -0.8 + random.nextDouble() * 1.6;
        final y = -0.1 + random.nextDouble() * 0.8;
        _fxBursts.add(
          _FxBurst(
            id: now + i,
            icon: icon,
            color: color.withValues(alpha: 0.95),
            alignment: Alignment(x, y),
          ),
        );
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _fxBursts.removeWhere((it) => it.id >= now && it.id < now + count + 1);
      });
    });
  }

  Duration _petCooldownRemaining(MascotProfile profile) {
    if (profile.lastPetTime == null) {
      return Duration.zero;
    }
    final remain =
        const Duration(minutes: 10) - _now.difference(profile.lastPetTime!);
    return remain.isNegative ? Duration.zero : remain;
  }

  Duration _feedCooldownRemaining(MascotProfile profile) {
    if (profile.lastFeedTime == null) {
      return Duration.zero;
    }
    final remain =
        const Duration(hours: 2) - _now.difference(profile.lastFeedTime!);
    return remain.isNegative ? Duration.zero : remain;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openTodayQuestion() async {
    final now = DateTime.now();
    final recordDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final slot = now.hour < 12 ? DailySlotType.morning : DailySlotType.evening;

    await _openDailyRecordDialog(slot: slot, recordDate: recordDate);
  }

  Future<void> _checkDailyQuestionPrompt() async {
    final now = DateTime.now();
    final recordDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final slot = now.hour < 12 ? DailySlotType.morning : DailySlotType.evening;

    final existing = await ref
        .read(dailyRecordControllerProvider)
        .getByDateAndSlot(recordDate: recordDate, slotType: slot);

    if (existing != null || !mounted) {
      return;
    }

    await _openDailyRecordDialog(slot: slot, recordDate: recordDate);
  }

  Future<void> _openDailyRecordDialog({
    required DailySlotType slot,
    required String recordDate,
  }) async {
    final existing = await ref
        .read(dailyRecordControllerProvider)
        .getByDateAndSlot(recordDate: recordDate, slotType: slot);

    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오늘의 문답은 이미 저장했어요.')));
      }
      return;
    }

    if (!mounted) {
      return;
    }

    final moodNotifier = ValueNotifier<int>(3);
    final answerController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(slot == DailySlotType.morning ? '오전 체크인' : '오후 체크인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('지금 기분은 어떤가요? (1~5 단계)'),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: moodNotifier,
                builder: (context, mood, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => moodNotifier.value = value,
                        icon: Icon(
                          mood >= value
                              ? Icons.sentiment_satisfied_alt
                              : Icons.sentiment_neutral,
                          color: mood >= value ? Colors.amber : null,
                        ),
                      );
                    }),
                  );
                },
              ),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: '오늘의 한 줄',
                  hintText: '오늘의 각오/회고를 남겨주세요',
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    final shouldSave = result == true;
    if (!shouldSave) {
      moodNotifier.dispose();
      answerController.dispose();
      return;
    }

    final answer = answerController.text.trim().isEmpty
        ? '기록 없음'
        : answerController.text.trim();

    await ref
        .read(dailyRecordControllerProvider)
        .addRecord(
          DailyRecord(
            recordDate: recordDate,
            slotType: slot,
            moodLevel: moodNotifier.value,
            questionText: slot == DailySlotType.morning
                ? '오늘 하루의 목표는 무엇인가요?'
                : '오늘 하루를 어떻게 마무리했나요?',
            userAnswer: answer,
            createdAt: DateTime.now(),
          ),
        );

    await ref.read(mascotProfileProvider.notifier).rewardFromDailyRecord();

    moodNotifier.dispose();
    answerController.dispose();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문답 저장 완료! 매화 EXP +20, 알 성장 진행 +1')),
      );
    }
  }
}

class _BrushingMissionDialog extends StatefulWidget {
  const _BrushingMissionDialog();

  @override
  State<_BrushingMissionDialog> createState() => _BrushingMissionDialogState();
}

class _BrushingMissionDialogState extends State<_BrushingMissionDialog> {
  int _leftSeconds = 15;
  int _strokeCount = 0;
  Timer? _timer;
  final List<_Particle> _particles = [];
  final List<Offset> _trailPoints = [];
  DateTime _lastFeedbackTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_leftSeconds <= 1) {
        timer.cancel();
        Navigator.of(context).pop(_strokeCount);
        return;
      }

      setState(() {
        _leftSeconds -= 1;
        _particles.removeWhere((particle) => particle.life <= 0);
        for (final p in _particles) {
          p.life -= 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Text('빗질하기', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text('남은 시간: $_leftSeconds초 · 스트로크: $_strokeCount'),
              const SizedBox(height: 10),
              SizedBox(
                height: 260,
                child: GestureDetector(
                  onPanUpdate: _onBrushDrag,
                  child: CustomPaint(
                    painter: _BrushPainter(
                      particles: _particles,
                      trailPoints: _trailPoints,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                        color: Colors.amber.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('드래그할 때마다 털 파티클 + 햅틱 + 빗질 사운드가 발생합니다.'),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_strokeCount),
                child: const Text('지금 종료하고 정산'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBrushDrag(DragUpdateDetails details) {
    final random = Random();

    final now = DateTime.now();
    if (now.difference(_lastFeedbackTime).inMilliseconds > 60) {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
      _lastFeedbackTime = now;
    }

    setState(() {
      _strokeCount += 1;
      _trailPoints.add(details.localPosition);
      if (_trailPoints.length > 100) {
        _trailPoints.removeAt(0);
      }

      _particles.add(
        _Particle(
          offset: details.localPosition,
          radius: 3 + random.nextDouble() * 6,
          life: 18,
          color: Colors.brown.withValues(alpha: 0.62),
        ),
      );
      if (_particles.length > 170) {
        _particles.removeAt(0);
      }
    });
  }
}

class _EggPainter extends CustomPainter {
  const _EggPainter({required this.crackDay});

  final int crackDay;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final eggPaint = Paint()..color = const Color(0xFFFFF5DD);
    final strokePaint = Paint()
      ..color = const Color(0xFFD8C8A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final eggPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.93,
        size.height * 0.2,
        size.width * 0.88,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.95,
        size.width * 0.5,
        size.height * 0.96,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.95,
        size.width * 0.12,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.07,
        size.height * 0.2,
        size.width * 0.5,
        size.height * 0.06,
      );

    canvas.drawShadow(eggPath, Colors.black.withValues(alpha: 0.18), 10, false);
    canvas.drawPath(eggPath, eggPaint);
    canvas.drawPath(eggPath, strokePaint);

    final crackPaint = Paint()
      ..color = const Color(0xFF8E7C61)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final intensity = crackDay.clamp(0, 7);
    for (var i = 0; i < intensity; i++) {
      final t = (i + 1) / 8;
      final x = size.width * (0.25 + 0.5 * t);
      final y = size.height * (0.2 + 0.6 * t);

      final crack = Path()
        ..moveTo(x - 8, y - 6)
        ..lineTo(x - 2, y + 3)
        ..lineTo(x + 5, y - 4)
        ..lineTo(x + 10, y + 6);

      canvas.drawPath(crack, crackPaint);
    }

    final dayTextPainter = TextPainter(
      text: TextSpan(
        text: '$crackDay/7',
        style: const TextStyle(
          color: Color(0xFF7A6B52),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    dayTextPainter.paint(
      canvas,
      Offset((size.width - dayTextPainter.width) / 2, size.height * 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant _EggPainter oldDelegate) {
    return oldDelegate.crackDay != crackDay;
  }
}

class _BrushPainter extends CustomPainter {
  const _BrushPainter({required this.particles, required this.trailPoints});

  final List<_Particle> particles;
  final List<Offset> trailPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final trailPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.45)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < trailPoints.length; i++) {
      canvas.drawLine(trailPoints[i - 1], trailPoints[i], trailPaint);
    }

    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.life / 18);
      canvas.drawCircle(particle.offset, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushPainter oldDelegate) {
    return oldDelegate.particles != particles ||
        oldDelegate.trailPoints != trailPoints;
  }
}

class _Particle {
  _Particle({
    required this.offset,
    required this.radius,
    required this.life,
    required this.color,
  });

  Offset offset;
  double radius;
  int life;
  Color color;
}

class _FxBurst {
  const _FxBurst({
    required this.id,
    required this.icon,
    required this.color,
    required this.alignment,
  });

  final int id;
  final IconData icon;
  final Color color;
  final Alignment alignment;
}
