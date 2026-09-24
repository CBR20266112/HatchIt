import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../mascot/presentation/mascot_controller.dart';
import '../../schedules/domain/schedule.dart';
import '../../schedules/presentation/schedule_controller.dart';

enum _MissionMascotState {
  alarmPanic,
  wakeDrowsy,
  missionClear,
  jump,
  missionFail,
  sadTeary,
}

const _missionMascotBase = 'assets/images/mascots/1';

const Map<_MissionMascotState, List<String>> _missionMascotCandidates = {
  _MissionMascotState.alarmPanic: ['alarm_panic.png', 'expr_surprised.png'],
  _MissionMascotState.wakeDrowsy: [
    'wake_drowsy.png',
    'wake_drowsy_blanket.png',
  ],
  _MissionMascotState.missionClear: ['mission_clear.png', 'groom_sparkle.png'],
  _MissionMascotState.jump: ['jump.png', 'mission_clear.png'],
  _MissionMascotState.missionFail: ['mission_fail.png', 'expr_pouty.png'],
  _MissionMascotState.sadTeary: ['expr_sad_teary.png', 'exp_teary.png'],
};

Widget _buildMissionMascotAsset(List<String> candidates) {
  Widget buildAt(int index) {
    if (index >= candidates.length) {
      return const Icon(Icons.pets_rounded, size: 72);
    }
    return Image.asset(
      '$_missionMascotBase/${candidates[index]}',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => buildAt(index + 1),
    );
  }

  return buildAt(0);
}

class MissionAlarmScreen extends ConsumerStatefulWidget {
  const MissionAlarmScreen({super.key});

  @override
  ConsumerState<MissionAlarmScreen> createState() => _MissionAlarmScreenState();
}

class _MissionAlarmScreenState extends ConsumerState<MissionAlarmScreen> {
  String _dismissStatus = '최근 미리 끄기 기록 없음';
  _MissionMascotState _missionMascotState = _MissionMascotState.alarmPanic;
  Timer? _missionMascotTimer;

  @override
  void dispose() {
    _missionMascotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedulesValue = ref.watch(scheduleListProvider);

    return schedulesValue.when(
      data: (schedules) {
        final shellSchedules = schedules;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('기상 & 미션', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _buildMissionMascotCard(),
            const SizedBox(height: 12),
            _buildDismissStatusCard(),
            const SizedBox(height: 12),
            _buildMissionPreviewCard(l10n),
            const SizedBox(height: 12),
            Text('알람 카드', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (shellSchedules.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('등록된 일정이 없습니다. 시간표 탭에서 먼저 일정을 추가해 주세요.'),
                ),
              )
            else
              ...shellSchedules.map(_buildAlarmCard),
          ],
        );
      },
      error: (error, stackTrace) => Center(child: Text('알람 로드 실패: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMissionMascotCard() {
    final labels = {
      _MissionMascotState.alarmPanic: '알람 울림! 지금 미션 시작!',
      _MissionMascotState.wakeDrowsy: '스누즈/미리 끄기 상태',
      _MissionMascotState.missionClear: '미션 통과! 아주 좋아요.',
      _MissionMascotState.jump: '성공 축하 점프!',
      _MissionMascotState.missionFail: '미션 실패, 다시 도전!',
      _MissionMascotState.sadTeary: '아쉬운 표정 모드',
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildMissionMascotAsset(
              _missionMascotCandidates[_missionMascotState]!,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labels[_missionMascotState]!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setMissionMascotState(_MissionMascotState next, {Duration? hold}) {
    _missionMascotTimer?.cancel();
    setState(() {
      _missionMascotState = next;
    });
    if (hold != null) {
      _missionMascotTimer = Timer(hold, () {
        if (!mounted) {
          return;
        }
        setState(() {
          _missionMascotState = _MissionMascotState.alarmPanic;
        });
      });
    }
  }

  Future<void> _runMissionResultSequence(bool success) async {
    if (success) {
      _setMissionMascotState(_MissionMascotState.missionClear);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) {
        return;
      }
      _setMissionMascotState(
        _MissionMascotState.jump,
        hold: const Duration(milliseconds: 1600),
      );
      await ref
          .read(mascotProfileProvider.notifier)
          .rewardFromMissionResult(success: true);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('미션 성공! 게이지가 크게 올랐어.')));
      return;
    }

    _setMissionMascotState(_MissionMascotState.missionFail);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }
    _setMissionMascotState(
      _MissionMascotState.sadTeary,
      hold: const Duration(milliseconds: 1600),
    );
    await ref
        .read(mascotProfileProvider.notifier)
        .rewardFromMissionResult(success: false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('미션 실패/시간 초과. 그래도 게이지는 조금 올랐어.')),
    );
  }

  Widget _buildDismissStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_off_outlined),
                const SizedBox(width: 8),
                Text(
                  '상단 알림 미리 끄기 상태',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_dismissStatus),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () async {
                setState(() {
                  _dismissStatus = '프리뷰: 사용자가 [미리 끄기]를 눌러 해당 알림 인스턴스를 해제했습니다.';
                });
                _setMissionMascotState(
                  _MissionMascotState.wakeDrowsy,
                  hold: const Duration(milliseconds: 1500),
                );
                await ref.read(mascotProfileProvider.notifier).rewardFromAlarmDismiss();
              },
              child: const Text('미리 끄기 UX 프리뷰'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionPreviewCard(AppLocalizations l10n) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('미션 미리보기', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.missionSample),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _openTracingMissionPreview,
                  icon: const Icon(Icons.brush_outlined),
                  label: const Text('선 따라그리기'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _openShakingMissionPreview,
                  icon: const Icon(Icons.vibration_outlined),
                  label: const Text('흔들기 미션'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(Schedule schedule) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        title: Text(
          schedule.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${_dayLabel(schedule.dayOfWeek)} ${schedule.startTime}~${schedule.endTime}\n${schedule.location ?? '장소 미지정'}',
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _offsetLabel(schedule.alarmOffsetMinutes),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }

  Future<void> _openTracingMissionPreview() async {
    _setMissionMascotState(_MissionMascotState.alarmPanic);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _TracingMissionDialog(),
    );
    if (result == null || !mounted) {
      return;
    }
    await _runMissionResultSequence(result);
  }

  Future<void> _openShakingMissionPreview() async {
    _setMissionMascotState(_MissionMascotState.alarmPanic);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _ShakingMissionDialog(),
    );
    if (result == null || !mounted) {
      return;
    }
    await _runMissionResultSequence(result);
  }

  String _offsetLabel(int minutes) {
    switch (minutes) {
      case 30:
        return '30분 전';
      case 60:
        return '1시간 전';
      case 90:
        return '1시간 반 전';
      case 120:
        return '2시간 전';
      default:
        return '$minutes분 전';
    }
  }

  String _dayLabel(int value) {
    switch (value) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '?';
    }
  }
}

class _TracingMissionDialog extends StatefulWidget {
  const _TracingMissionDialog();

  @override
  State<_TracingMissionDialog> createState() => _TracingMissionDialogState();
}

class _TracingMissionDialogState extends State<_TracingMissionDialog> {
  final List<Offset> _points = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tracing Mission 프리뷰'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('박스 안에서 선을 그리며 흔적 20개 이상을 남겨보세요.'),
            const SizedBox(height: 8),
            Text('현재 흔적: ${_points.length}'),
            const SizedBox(height: 8),
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                  if (_points.length > 250) {
                    _points.removeAt(0);
                  }
                });
              },
              child: CustomPaint(
                painter: _TracePainter(points: _points),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.45),
                    ),
                    color: Colors.blue.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: () {
            final ok = _points.length >= 20;
            Navigator.of(context).pop(ok);
          },
          child: const Text('판정하기'),
        ),
      ],
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _ShakingMissionDialog extends StatefulWidget {
  const _ShakingMissionDialog();

  @override
  State<_ShakingMissionDialog> createState() => _ShakingMissionDialogState();
}

class _ShakingMissionDialogState extends State<_ShakingMissionDialog> {
  StreamSubscription<AccelerometerEvent>? _subscription;
  int _shakeCount = 0;
  Timer? _timer;
  int _leftSeconds = 8;

  @override
  void initState() {
    super.initState();
    _startMission();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shaking Mission 프리뷰'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('남은 시간: $_leftSeconds초'),
          const SizedBox(height: 8),
          Text('감지된 흔들기: $_shakeCount회'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _leftSeconds / 8),
          const SizedBox(height: 12),
          Text(
            kIsWeb
                ? '웹 환경에서는 실제 가속도 센서가 제한될 수 있어요. 아래 시뮬레이션 버튼으로 테스트할 수 있습니다.'
                : '실기기에서는 흔들기 센서로 자동 판정됩니다. 필요하면 시뮬레이션 버튼도 함께 사용하세요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _simulateShake,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('가속도 시뮬레이션 +1'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  void _registerShake() {
    if (!mounted || _leftSeconds <= 0) {
      return;
    }
    setState(() {
      _shakeCount += 1;
    });
  }

  void _simulateShake() {
    _registerShake();
  }

  void _startMission() {
    final random = Random();

    _subscription = accelerometerEventStream().listen((event) {
      final force = event.x.abs() + event.y.abs() + event.z.abs();
      final threshold = 26 + random.nextDouble() * 3;
      if (force > threshold) {
        _registerShake();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_leftSeconds <= 1) {
        timer.cancel();
        _subscription?.cancel();
        final success = _shakeCount >= 7;
        Navigator.of(context).pop(success);
        return;
      }

      setState(() {
        _leftSeconds -= 1;
      });
    });
  }
}
