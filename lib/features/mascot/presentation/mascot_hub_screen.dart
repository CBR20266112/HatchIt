import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../assistant/data/gemini_assistant_service.dart';
import '../../daily_records/domain/daily_record.dart';
import '../../daily_records/presentation/daily_record_controller.dart';
import '../../schedules/domain/schedule.dart';
import '../../schedules/presentation/schedule_controller.dart';
import '../domain/mascot_profile.dart';
import '../domain/mascot_species.dart';
import 'mascot_controller.dart';
enum _HubVisualState {
  idle,
  sleeping,
  curiousTap,
  happy,
  waving,
  studyBurn,
  alarmPanic,
  pouty,
  petSnuggle,
  feedEating,
  feedFull,
  grooming,
  groomSparkle,
  holdFurball,
  eggHatch,
}

const Map<_HubVisualState, List<String>> _hubVisualCandidates = {
  _HubVisualState.idle: ['idle.png', 'view_front.png'],
  _HubVisualState.sleeping: [
    'sleeping.png',
    'action_sleep.png',
    'exp_sleepy.png',
  ],
  _HubVisualState.curiousTap: [
    'curious_tap.png',
    'view_34.png',
    'exp_focus.png',
  ],
  _HubVisualState.happy: ['expr_happy.png', 'exp_happy.png', 'talking.png'],
  _HubVisualState.waving: ['waving.png', 'waving_alt.png', 'action_wave.png'],
  _HubVisualState.studyBurn: ['study_burn.png', 'typing.png', 'reading.png'],
  _HubVisualState.alarmPanic: ['alarm_panic.png', 'expr_surprised.png'],
  _HubVisualState.pouty: ['expr_pouty.png', 'exp_pout.png', 'exp_angry.png'],
  _HubVisualState.petSnuggle: [
    'pet_snuggle.png',
    'petting.png',
    'exp_touched.png',
  ],
  _HubVisualState.feedEating: [
    'feed_eating.png',
    'feeding.png',
    'action_cooking.png',
  ],
  _HubVisualState.feedFull: [
    'feed_full.png',
    'action_cooking.png',
    'action_box.png',
  ],
  _HubVisualState.grooming: ['grooming.png'],
  _HubVisualState.groomSparkle: [
    'groom_sparkle.png',
    'exp_touched.png',
    'action_wave.png',
  ],
  _HubVisualState.holdFurball: ['hold_furball.png', 'action_box.png'],
  _HubVisualState.eggHatch: ['egg_hatch.png', 'idle_4.png', 'idle_3.png'],
};

const _hubTapReactionPool = [_HubVisualState.curiousTap, _HubVisualState.happy];

class _EggDailyQuestion {
  const _EggDailyQuestion({
    required this.question,
    required this.axis,
    required this.positiveLabel,
    required this.negativeLabel,
  });

  final String question;
  final PersonalityAxis axis;
  final String positiveLabel;
  final String negativeLabel;
}

const List<_EggDailyQuestion> _eggDailyQuestions = [
  _EggDailyQuestion(
    question: 'Day 1 · 너는 아침형이야, 밤형이야?',
    axis: PersonalityAxis.rhythm,
    positiveLabel: '밤에 더 집중됨 (야행성)',
    negativeLabel: '아침이 더 잘 맞음 (아침형)',
  ),
  _EggDailyQuestion(
    question: 'Day 2 · 과제 스타일은?',
    axis: PersonalityAxis.execution,
    positiveLabel: '마감 직전 스퍼트형',
    negativeLabel: '계획대로 꾸준형',
  ),
  _EggDailyQuestion(
    question: 'Day 3 · 공부할 때 어디가 더 편해?',
    axis: PersonalityAxis.cognition,
    positiveLabel: '글/서술 중심 과목이 편함',
    negativeLabel: '수학/논리 중심 과목이 편함',
  ),
  _EggDailyQuestion(
    question: 'Day 4 · 에너지는 어느 쪽?',
    axis: PersonalityAxis.energy,
    positiveLabel: '활동적이고 에너지 넘침',
    negativeLabel: '차분하고 조용한 편',
  ),
  _EggDailyQuestion(
    question: 'Day 5 · 시험 기간 루틴은?',
    axis: PersonalityAxis.rhythm,
    positiveLabel: '밤샘 집중 루틴',
    negativeLabel: '아침 일찍 시작 루틴',
  ),
  _EggDailyQuestion(
    question: 'Day 6 · 과제 시작 방식은?',
    axis: PersonalityAxis.execution,
    positiveLabel: '한 번에 몰아서 처리',
    negativeLabel: '쪼개서 미리 처리',
  ),
  _EggDailyQuestion(
    question: 'Day 7 · 팀플에서 나는?',
    axis: PersonalityAxis.energy,
    positiveLabel: '발표/진행 맡는 편',
    negativeLabel: '자료 정리/분석 맡는 편',
  ),
];

bool _isNightSleepWindow(DateTime now) => now.hour >= 23 || now.hour < 6;

List<String> _eggCandidates(int crackDay) {
  final stage = crackDay.clamp(0, 6);
  return ['egg_$stage.png', 'egg_0.png'];
}

Widget _buildAssetWithFallback({
  required String base,
  required List<String> candidates,
  required double width,
  required double height,
  required BoxFit fit,
  required Widget Function() onAllFailed,
}) {
  Widget buildAt(int index) {
    if (index >= candidates.length) {
      return onAllFailed();
    }
    return Image.asset(
      '$base/${candidates[index]}',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildAt(index + 1),
    );
  }

  return buildAt(0);
}

String _cooldownButtonLabel(String base, Duration remain) {
  if (remain == Duration.zero) {
    return base;
  }
  final minutes = remain.inMinutes;
  final seconds = remain.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '쿨타임 ${minutes.toString().padLeft(2, '0')}:$seconds';
}

String _debugVisualLabel(_HubVisualState state) {
  switch (state) {
    case _HubVisualState.idle:
      return '기본 대기';
    case _HubVisualState.sleeping:
      return '수면 모드';
    case _HubVisualState.curiousTap:
      return '깜짝 반응';
    case _HubVisualState.happy:
      return '해피 반응';
    case _HubVisualState.waving:
      return '손인사 반응';
    case _HubVisualState.studyBurn:
      return '집중 버닝 모드';
    case _HubVisualState.alarmPanic:
      return '알람 패닉 모드';
    case _HubVisualState.pouty:
      return '삐짐 반응';
    case _HubVisualState.petSnuggle:
      return '쓰다듬기 성공';
    case _HubVisualState.feedEating:
      return '냠냠 먹는 중';
    case _HubVisualState.feedFull:
      return '만족 상태';
    case _HubVisualState.grooming:
      return '빗질 진행';
    case _HubVisualState.groomSparkle:
      return '빗질 완료 반짝';
    case _HubVisualState.holdFurball:
      return '털뭉치 획득';
    case _HubVisualState.eggHatch:
      return '부화 순간';
  }
}

class MascotHubScreen extends ConsumerStatefulWidget {
  const MascotHubScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<MascotHubScreen> createState() => _MascotHubScreenState();
}

class _MascotHubScreenState extends ConsumerState<MascotHubScreen> {
  Timer? _uiTicker;
  Timer? _visualStateTimer;
  DateTime _now = DateTime.now();
  bool _hatchFlashVisible = false;
  final List<_FxBurst> _fxBursts = [];
  final Random _random = Random();
  final GeminiAssistantService _assistantService = const GeminiAssistantService();
  _HubVisualState? _forcedVisualState;
  bool _isBrushingInProgress = false;
  bool _eggHatchModalShown = false;
  bool _isTodayQuestionAnswered = false;
  String? _todayQuestionCheckedDate;
  MascotStage? _lastKnownStage;
  Timer? _assistantBubbleTimer;
  String? _assistantBubbleText;
  bool _assistantBubbleVisible = false;
  bool _isAssistantBusy = false;

  @override
  void initState() {
    super.initState();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final nextNow = DateTime.now();
      final previousDate = _dateKey(_now);
      final nextDate = _dateKey(nextNow);
      setState(() {
        _now = nextNow;
      });
      if (previousDate != nextDate) {
        unawaited(_syncTodayQuestionStatus());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncTodayQuestionStatus();
      await _checkDailyQuestionPrompt();
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _visualStateTimer?.cancel();
    _assistantBubbleTimer?.cancel();
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

        _trackEggHatchTransition(profile);

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
            if (_hatchFlashVisible)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _hatchFlashVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(color: Colors.white.withValues(alpha: 0.85)),
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
    final isLight =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light;
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
    final speaking = _resolveMascotSpeech(profile);
    final species = MascotSpeciesDefinition.byId(profile.speciesId ?? 1);
    final isEgg = profile.currentStage == MascotStage.egg;
    final base = isEgg ? 'assets/images/eggs' : species.assetBasePath;
    final visualState = _resolveVisualState(profile, canBrush: canBrush);
    final candidates = _resolveVisualCandidates(profile, visualState);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(speaking),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '삼순이에게 말하기',
                onPressed: _isAssistantBusy ? null : () => _openAssistantInputSheet(),
                icon: _isAssistantBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_horiz_rounded),
              ),
            ],
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
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: isEgg ? null : _onMascotTap,
                    child: isEgg
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0.96,
                              end: 1 + (0.02 * sin(_now.millisecond / 160)),
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(scale: value, child: child);
                            },
                            child: _buildAssetWithFallback(
                              base: base,
                              candidates: candidates,
                              width: 190,
                              height: 190,
                              fit: BoxFit.contain,
                              onAllFailed: () {
                                return CustomPaint(
                                  size: const Size(150, 180),
                                  painter: _EggPainter(crackDay: profile.eggCrackDay),
                                );
                              },
                            ),
                          )
                        : _buildAssetWithFallback(
                            base: base,
                            candidates: candidates,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            onAllFailed: () {
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
                if (_assistantBubbleText != null)
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: AnimatedOpacity(
                      opacity: _assistantBubbleVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      child: _buildAssistantDialogueBubble(_assistantBubbleText!),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _debugVisualLabel(visualState),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (isEgg) ...[
            const SizedBox(height: 10),
            _buildDailyQuestionCard(profile),
          ],
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

  Widget _buildDailyQuestionCard(MascotProfile profile) {
    final dayIndex = profile.eggCrackDay.clamp(0, _eggDailyQuestions.length - 1);
    final question = _eggDailyQuestions[dayIndex];
    final answeredToday = _isTodayQuestionAnswered;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 질문 · ${profile.eggCrackDay + 1} / 7',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(question.question),
            const SizedBox(height: 10),
            if (answeredToday)
              Text(
                '오늘 질문은 이미 완료했어. 내일 다시 열릴게! 🌙',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _submitDailyEggAnswer(
                          question: question,
                          choosePositive: true,
                        );
                      },
                      child: Text(question.positiveLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _submitDailyEggAnswer(
                          question: question,
                          choosePositive: false,
                        );
                      },
                      child: Text(question.negativeLabel),
                    ),
                  ),
                ],
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
                    onPressed: () => _onPet(palette),
                    icon: const Icon(Icons.pan_tool_alt_outlined),
                    label: Text(_cooldownButtonLabel('쓰다듬기', petRemain)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _onFeed(palette),
                    icon: const Icon(Icons.ramen_dining),
                    label: Text(_cooldownButtonLabel('밥주기', feedRemain)),
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

  Widget _buildAssistantDialogueBubble(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.surface,
            size: 26,
          ),
        ),
      ],
    );
  }

  Future<void> _openAssistantInputSheet() async {
    final controller = TextEditingController();
    final prompt = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '삼순이에게 말하기',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '예) 내일 오후 2시 자료구조 일정 추가해줘',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop(value.trim());
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(controller.text.trim());
                      },
                      child: const Text('보내기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (prompt == null || prompt.trim().isEmpty || !mounted) {
      return;
    }

    await _processAssistantInput(prompt);
  }

  Future<void> _processAssistantInput(String userPrompt) async {
    final settings = ref.read(settingsControllerProvider);
    const envGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
    final apiKey = settings.geminiApiKey.trim().isNotEmpty
        ? settings.geminiApiKey.trim()
        : envGeminiApiKey.trim();

    if (apiKey.isEmpty) {
      _showAssistantBubble('API 키를 먼저 설정해줘! 설정에서 Gemini 키 등록 가능해 😺');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Key가 없습니다. 설정에서 등록하거나 --dart-define로 주입하세요.'),
        ),
      );
      return;
    }

    setState(() {
      _isAssistantBusy = true;
    });

    try {
      final response = await _assistantService.ask(
        userInput: userPrompt,
        apiKey: apiKey,
        now: DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      await _applyAssistantResponse(response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAssistantBubble('응답을 처리하다가 문제가 생겼어. 다시 말해줘!');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI 비서 요청 실패: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isAssistantBusy = false;
        });
      }
    }
  }

  Future<void> _applyAssistantResponse(AssistantResponse response) async {
    switch (response.action) {
      case AssistantAction.createSchedule:
        final scheduleData = response.scheduleData;
        if (scheduleData != null) {
          await ref
              .read(scheduleListProvider.notifier)
              .addSchedule(_scheduleFromAssistant(scheduleData));
        }
        break;
      case AssistantAction.setAlarm:
        final alarmData = response.alarmData;
        if (alarmData != null) {
          if (alarmData.isEnabled) {
            await _upsertWakeAlarmSchedule(alarmData.targetTime);
          } else {
            await _removeWakeAlarmSchedules();
          }
        }
        break;
      case AssistantAction.toggleAlarm:
        final alarmData = response.alarmData;
        if (alarmData == null || alarmData.isEnabled) {
          final time = alarmData?.targetTime ?? '08:30';
          await _upsertWakeAlarmSchedule(time);
        } else {
          await _removeWakeAlarmSchedules();
        }
        break;
      case AssistantAction.chat:
        break;
    }

    _showAssistantBubble(response.dialogue);
    _setForcedVisual(
      _emotionToVisualState(response.mascotEmotion),
      duration: const Duration(seconds: 2),
    );
  }

  Schedule _scheduleFromAssistant(AssistantScheduleData data) {
    return Schedule(
      title: data.title,
      type: ScheduleType.event,
      dayOfWeek: data.dayOfWeek,
      startTime: data.startTime,
      endTime: data.endTime,
      location: 'AI 비서 추가',
      isCompleted: false,
      alarmOffsetMinutes: 30,
    );
  }

  Future<void> _upsertWakeAlarmSchedule(String targetTime) async {
    final list = ref.read(scheduleListProvider).valueOrNull ?? const <Schedule>[];
    final weekday = _weekdayFromDate(DateTime.now());
    final endTime = _addMinutesToClock(targetTime, 30);

    final existing = list.where((it) => it.title == '기상 알람').toList();
    if (existing.isEmpty) {
      await ref.read(scheduleListProvider.notifier).addSchedule(
            Schedule(
              title: '기상 알람',
              type: ScheduleType.event,
              dayOfWeek: weekday,
              startTime: targetTime,
              endTime: endTime,
              location: 'AI 비서 설정',
              isCompleted: false,
              alarmOffsetMinutes: 30,
            ),
          );
      return;
    }

    for (final item in existing) {
      if (item.id == null) {
        continue;
      }
      await ref.read(scheduleListProvider.notifier).updateSchedule(
            item.copyWith(
              dayOfWeek: weekday,
              startTime: targetTime,
              endTime: endTime,
              isCompleted: false,
              alarmOffsetMinutes: 30,
            ),
          );
    }
  }

  Future<void> _removeWakeAlarmSchedules() async {
    final list = ref.read(scheduleListProvider).valueOrNull ?? const <Schedule>[];
    final targets = list.where((it) => it.title == '기상 알람');
    for (final item in targets) {
      if (item.id == null) {
        continue;
      }
      await ref.read(scheduleListProvider.notifier).removeSchedule(item.id!);
    }
  }

  _HubVisualState _emotionToVisualState(String emotion) {
    switch (emotion.trim().toLowerCase()) {
      case 'waving':
        return _HubVisualState.waving;
      case 'study_burn':
        return _HubVisualState.studyBurn;
      case 'alarm_panic':
        return _HubVisualState.alarmPanic;
      case 'expr_pouty':
        return _HubVisualState.pouty;
      case 'expr_sad_teary':
        return _HubVisualState.pouty;
      case 'expr_surprised':
        return _HubVisualState.curiousTap;
      case 'expr_happy':
      default:
        return _HubVisualState.happy;
    }
  }

  void _showAssistantBubble(String text, {int seconds = 8}) {
    _assistantBubbleTimer?.cancel();
    if (!mounted) {
      return;
    }

    setState(() {
      _assistantBubbleText = text;
      _assistantBubbleVisible = true;
    });

    _assistantBubbleTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _assistantBubbleVisible = false;
      });
      Future<void>.delayed(const Duration(milliseconds: 340), () {
        if (!mounted || _assistantBubbleVisible) {
          return;
        }
        setState(() {
          _assistantBubbleText = null;
        });
      });
    });
  }

  int _weekdayFromDate(DateTime date) {
    return date.weekday.clamp(1, 7);
  }

  String _addMinutesToClock(String hhmm, int minutes) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return '09:00';
    }
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 30;
    final total = hour * 60 + minute + minutes;
    final normalized = ((total % (24 * 60)) + (24 * 60)) % (24 * 60);
    final hh = normalized ~/ 60;
    final mm = normalized % 60;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  _HubVisualState _resolveVisualState(
    MascotProfile profile, {
    required bool canBrush,
  }) {
    if (_forcedVisualState != null) {
      return _forcedVisualState!;
    }
    if (profile.currentStage == MascotStage.egg) {
      return _HubVisualState.idle;
    }
    if (_isBrushingInProgress || canBrush) {
      return _HubVisualState.grooming;
    }
    if (_isNightSleepWindow(_now)) {
      return _HubVisualState.sleeping;
    }
    return _HubVisualState.idle;
  }

  List<String> _resolveVisualCandidates(
    MascotProfile profile,
    _HubVisualState state,
  ) {
    if (profile.currentStage == MascotStage.egg &&
        state != _HubVisualState.eggHatch) {
      return _eggCandidates(profile.eggCrackDay);
    }
    return _hubVisualCandidates[state] ??
        _hubVisualCandidates[_HubVisualState.idle]!;
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
      _setForcedVisual(
        _HubVisualState.petSnuggle,
        duration: const Duration(seconds: 2),
      );
      _spawnBurst(icon: Icons.favorite, color: palette.emotionHot, count: 8);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쓰다듬기 성공! 게이지 +15% (쿨타임 10분)')),
      );
    } else {
      _setForcedVisual(
        _HubVisualState.pouty,
        duration: const Duration(milliseconds: 1500),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 쿨타임이에요. 삐졌어요. 잠깐 뒤에 다시!')),
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
      _setForcedVisual(_HubVisualState.feedEating);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) {
        return;
      }
      _setForcedVisual(_HubVisualState.feedFull);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) {
        return;
      }
      _clearForcedVisual();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('밥주기 성공! 냠냠 → 포만 완료')));
    } else {
      _setForcedVisual(
        _HubVisualState.pouty,
        duration: const Duration(milliseconds: 1500),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('밥주기는 2시간 쿨타임입니다.')));
    }
  }

  Future<void> _startBrushingModal() async {
    _isBrushingInProgress = true;
    _setForcedVisual(_HubVisualState.grooming);

    final strokeCount = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BrushingMissionDialog(),
    );

    _isBrushingInProgress = false;

    if (strokeCount == null || !mounted) {
      _clearForcedVisual();
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

    _setForcedVisual(_HubVisualState.groomSparkle);
    await showDialog<void>(
      context: context,
      builder: (context) {
        final species = MascotSpeciesDefinition.byId(
          ref.read(mascotProfileProvider).value?.speciesId ?? 1,
        );
        final base = species.assetBasePath;
        return AlertDialog(
          title: const Text('빗질 완료!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAssetWithFallback(
                      base: base,
                      candidates:
                          _hubVisualCandidates[_HubVisualState.groomSparkle]!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      onAllFailed: () => const SizedBox.shrink(),
                    ),
                  ),
                  Expanded(
                    child: _buildAssetWithFallback(
                      base: base,
                      candidates:
                          _hubVisualCandidates[_HubVisualState.holdFurball]!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      onAllFailed: () => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('털뭉치 +$reward 획득!'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    _setForcedVisual(
      _HubVisualState.holdFurball,
      duration: const Duration(milliseconds: 1200),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('빗질 종료! 털뭉치 +$reward, 게이지 0% 리셋 완료')),
    );
  }

  void _onMascotTap() {
    final picked =
        _hubTapReactionPool[_random.nextInt(_hubTapReactionPool.length)];
    _setForcedVisual(picked, duration: const Duration(milliseconds: 1200));
  }

  void _setForcedVisual(_HubVisualState state, {Duration? duration}) {
    _visualStateTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _forcedVisualState = state;
    });

    if (duration != null) {
      _visualStateTimer = Timer(duration, _clearForcedVisual);
    }
  }

  void _clearForcedVisual() {
    _visualStateTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _forcedVisualState = null;
    });
  }

  void _trackEggHatchTransition(MascotProfile profile) {
    final previous = _lastKnownStage;
    _lastKnownStage = profile.currentStage;

    if (profile.currentStage == MascotStage.egg) {
      _eggHatchModalShown = false;
      return;
    }

    if (previous == MascotStage.egg && !_eggHatchModalShown) {
      _eggHatchModalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showEggHatchModal();
      });
    }
  }

  Future<void> _showEggHatchModal() async {
    _setForcedVisual(_HubVisualState.eggHatch);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('부화 완료!'),
          content: _buildAssetWithFallback(
            base: 'assets/images/eggs',
            candidates: const ['egg_hatch.png'],
            width: 220,
            height: 220,
            fit: BoxFit.contain,
            onAllFailed: () => const Icon(Icons.auto_awesome_rounded, size: 80),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('시작하자!'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }
    _clearForcedVisual();
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

  Future<void> _openTodayQuestion() async {
    final profile = ref.read(mascotProfileProvider).valueOrNull;
    if (profile == null || profile.currentStage != MascotStage.egg) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 부화 완료! 마스코트와 함께 일정 관리해봐.')));
      return;
    }

    await _syncTodayQuestionStatus();
    if (!mounted) {
      return;
    }

    if (_isTodayQuestionAnswered) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘의 질문은 완료했어. 내일 다시 열릴게!')));
      return;
    }

    final dayIndex = profile.eggCrackDay.clamp(0, _eggDailyQuestions.length - 1);
    final question = _eggDailyQuestions[dayIndex];

    final choosePositive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('오늘의 질문 · ${profile.eggCrackDay + 1}/7'),
          content: Text(question.question),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(question.negativeLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(question.positiveLabel),
            ),
          ],
        );
      },
    );

    if (choosePositive == null) {
      return;
    }

    await _submitDailyEggAnswer(
      question: question,
      choosePositive: choosePositive,
    );
  }

  Future<void> _syncTodayQuestionStatus() async {
    final today = _dateKey(DateTime.now());
    final controller = ref.read(dailyRecordControllerProvider);
    final morning = await controller.getByDateAndSlot(
      recordDate: today,
      slotType: DailySlotType.morning,
    );
    final evening = await controller.getByDateAndSlot(
      recordDate: today,
      slotType: DailySlotType.evening,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _todayQuestionCheckedDate = today;
      _isTodayQuestionAnswered = morning != null || evening != null;
    });
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _answeredDailyQuestionToday() async {
    final today = _dateKey(DateTime.now());
    if (_todayQuestionCheckedDate == today) {
      return _isTodayQuestionAnswered;
    }

    await _syncTodayQuestionStatus();
    return _isTodayQuestionAnswered;
  }

  Future<void> _submitDailyEggAnswer({
    required _EggDailyQuestion question,
    required bool choosePositive,
  }) async {
    if (await _answeredDailyQuestionToday()) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘은 이미 답변 완료! 내일 다시 시도해줘.')));
      return;
    }

    final beforeProfile = ref.read(mascotProfileProvider).valueOrNull;
    if (beforeProfile == null || beforeProfile.currentStage != MascotStage.egg) {
      return;
    }

    final now = DateTime.now();
    final recordDate = _dateKey(now);
    final slot = now.hour < 12 ? DailySlotType.morning : DailySlotType.evening;

    await ref
        .read(dailyRecordControllerProvider)
        .addRecord(
          DailyRecord(
            recordDate: recordDate,
            slotType: slot,
            moodLevel: choosePositive ? 4 : 2,
            questionText: question.question,
            userAnswer: choosePositive
                ? question.positiveLabel
                : question.negativeLabel,
            createdAt: now,
          ),
        );

    await ref
        .read(mascotProfileProvider.notifier)
        .submitDailyEggAnswer(
          axis: question.axis,
          choosePositive: choosePositive,
        );

    HapticFeedback.mediumImpact();
    await _syncTodayQuestionStatus();

    final afterProfile = ref.read(mascotProfileProvider).valueOrNull;
    final hatchedNow =
        beforeProfile.currentStage == MascotStage.egg &&
        afterProfile?.currentStage == MascotStage.hatched;

    if (hatchedNow) {
      await _playHatchFlash();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('7일 문답 완료! 알이 부화했어 🎉')),
      );
      return;
    }

    if (!mounted || afterProfile == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('답변 완료! 알 균열 단계 ${afterProfile.eggCrackDay}/7'),
      ),
    );
  }

  Future<void> _playHatchFlash() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _hatchFlashVisible = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) {
      return;
    }
    setState(() {
      _hatchFlashVisible = false;
    });
  }

  String _resolveMascotSpeech(MascotProfile profile) {
    if (profile.currentStage == MascotStage.egg) {
      final day = (profile.eggCrackDay + 1).clamp(1, 7);
      if (_isTodayQuestionAnswered) {
        return '오늘 문답은 완료했어. Day $day 준비하면서 내일 다시 오자!';
      }
      return 'Day $day 질문에 답해주면 알이 더 갈라져!';
    }

    return '부화 완료! 이제 본격적으로 일정이랑 미션을 같이 관리해보자 ✨';
  }

  Future<void> _checkDailyQuestionPrompt() async {
    final profile = ref.read(mascotProfileProvider).valueOrNull;
    if (profile == null || profile.currentStage != MascotStage.egg) {
      return;
    }
    await _syncTodayQuestionStatus();
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
