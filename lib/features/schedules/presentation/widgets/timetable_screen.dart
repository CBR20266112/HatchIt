import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/schedule.dart';
import '../schedule_controller.dart';
import 'schedule_form_dialog.dart';

enum _TimetableViewMode { weekly, monthly }

enum _TimetableMascotState {
  studyBurn,
  classNodding,
  reading,
  campusWalk,
  waving,
}

const _timetableMascotBase = 'assets/images/mascots/1';

const Map<_TimetableMascotState, List<String>> _timetableMascotCandidates = {
  _TimetableMascotState.studyBurn: ['study_burn.png', 'action_study.png'],
  _TimetableMascotState.classNodding: ['class_nodding.png', 'action_idea.png'],
  _TimetableMascotState.reading: ['reading.png', 'action_study.png'],
  _TimetableMascotState.campusWalk: ['campus_walk.png', 'action_travel.png'],
  _TimetableMascotState.waving: [
    'waving.png',
    'waving_alt.png',
    'action_wave.png',
  ],
};

Widget _buildTimetableMascotAsset({
  required List<String> candidates,
  required double width,
  required double height,
}) {
  Widget buildAt(int index) {
    if (index >= candidates.length) {
      return const Icon(Icons.pets_rounded, size: 72);
    }
    return Image.asset(
      '$_timetableMascotBase/${candidates[index]}',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => buildAt(index + 1),
    );
  }

  return buildAt(0);
}

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  final _apiKeyController = TextEditingController();
  final _imagePicker = ImagePicker();
  _TimetableViewMode _mode = _TimetableViewMode.weekly;

  bool _isImporting = false;
  _TimetableMascotState? _forcedMascotState;
  Timer? _mascotTimer;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _mascotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedulesValue = ref.watch(scheduleListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: schedulesValue.when(
        data: (schedules) {
          final effectiveSchedules = schedules.isEmpty
              ? _mockSchedules
              : schedules;
          final mascotState = _resolveTimetableMascotState(effectiveSchedules);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '해칫 시간표',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      schedules.isEmpty
                          ? 'Mock 시간표'
                          : '${schedules.length}개 일정',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMascotStatusBanner(mascotState),
              const SizedBox(height: 12),
              SegmentedButton<_TimetableViewMode>(
                segments: const [
                  ButtonSegment(
                    value: _TimetableViewMode.weekly,
                    label: Text('주간 시간표'),
                  ),
                  ButtonSegment(
                    value: _TimetableViewMode.monthly,
                    label: Text('월간 캘린더'),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (next) {
                  setState(() {
                    _mode = next.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _mode == _TimetableViewMode.weekly
                    ? _buildWeeklyTimetable(
                        effectiveSchedules,
                        key: const ValueKey('weekly'),
                      )
                    : _buildMonthlyCalendar(
                        effectiveSchedules,
                        key: const ValueKey('monthly'),
                      ),
              ),
              const SizedBox(height: 12),
              _buildScheduleListPreview(effectiveSchedules, l10n),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('시간표 로드 실패: $error'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isImporting ? null : _openQuickActions,
        tooltip: '시간표 추가',
        child: _isImporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeeklyTimetable(List<Schedule> schedules, {required Key key}) {
    final weekdays = [(1, '월'), (2, '화'), (3, '수'), (4, '목'), (5, '금')];
    const startHour = 8;
    const endHour = 21;
    const rowHeight = 46.0;

    final classSchedules = schedules
        .where((s) => s.dayOfWeek >= 1 && s.dayOfWeek <= 5)
        .toList();

    return Card(
      key: key,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 38),
                ...weekdays.map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: (endHour - startHour) * rowHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final leftTimeWidth = 38.0;
                  final bodyWidth = constraints.maxWidth - leftTimeWidth;
                  final dayWidth = bodyWidth / 5;

                  return Stack(
                    children: [
                      for (int h = startHour; h <= endHour; h++)
                        Positioned(
                          top: (h - startHour) * rowHeight,
                          left: leftTimeWidth,
                          right: 0,
                          child: Divider(
                            height: 1,
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      for (int h = startHour; h < endHour; h++)
                        Positioned(
                          top: (h - startHour) * rowHeight - 8,
                          left: 0,
                          width: leftTimeWidth,
                          child: Text(
                            '$h',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      for (int i = 1; i < 5; i++)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: leftTimeWidth + (dayWidth * i),
                          child: VerticalDivider(
                            width: 1,
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ...classSchedules.map((schedule) {
                        final start = _toMinutes(schedule.startTime);
                        final end = _toMinutes(schedule.endTime);
                        final top = ((start - startHour * 60) / 60) * rowHeight;
                        final height = ((end - start) / 60) * rowHeight;
                        final left =
                            leftTimeWidth +
                            (schedule.dayOfWeek - 1) * dayWidth +
                            4;

                        final blockColor = _pastelColorFor(
                          schedule.id ?? schedule.title.hashCode,
                        );

                        return Positioned(
                          top: top.clamp(
                            0,
                            (endHour - startHour) * rowHeight - 24,
                          ),
                          left: left,
                          width: dayWidth - 8,
                          height: height.clamp(36, 220),
                          child: Material(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                _openScheduleDetailDialog(schedule);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${schedule.startTime}~${schedule.endTime}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar(List<Schedule> schedules, {required Key key}) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekdayOffset = firstDay.weekday % 7;

    final slots = List<int?>.generate(42, (index) {
      final day = index - firstWeekdayOffset + 1;
      if (day < 1 || day > daysInMonth) {
        return null;
      }
      return day;
    });

    return Card(
      key: key,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              '${now.year}년 ${now.month}월',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Center(child: Text('일'))),
                Expanded(child: Center(child: Text('월'))),
                Expanded(child: Center(child: Text('화'))),
                Expanded(child: Center(child: Text('수'))),
                Expanded(child: Center(child: Text('목'))),
                Expanded(child: Center(child: Text('금'))),
                Expanded(child: Center(child: Text('토'))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final day = slots[index];
                if (day == null) {
                  return const SizedBox.shrink();
                }

                final fakeWeekday = DateTime(now.year, now.month, day).weekday;
                final count = schedules
                    .where((s) => s.dayOfWeek == fakeWeekday)
                    .length;
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count개',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleListPreview(
    List<Schedule> schedules,
    AppLocalizations l10n,
  ) {
    if (schedules.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.ocrStub} · 아직 일정이 없습니다.'),
        ),
      );
    }

    final preview = schedules.take(3).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('다가오는 일정 미리보기', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...preview.map((schedule) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(schedule.title),
                subtitle: Text(
                  '${_dayLabel(schedule.dayOfWeek)} · ${schedule.startTime}~${schedule.endTime}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  child: Text(_offsetLabel(schedule.alarmOffsetMinutes)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  _TimetableMascotState _resolveTimetableMascotState(List<Schedule> schedules) {
    if (_forcedMascotState != null) {
      return _forcedMascotState!;
    }

    if (_isClassInProgress(schedules)) {
      final now = DateTime.now();
      return now.minute.isEven
          ? _TimetableMascotState.studyBurn
          : _TimetableMascotState.classNodding;
    }

    final now = DateTime.now();
    return now.minute.isEven
        ? _TimetableMascotState.reading
        : _TimetableMascotState.campusWalk;
  }

  bool _isClassInProgress(List<Schedule> schedules) {
    final now = DateTime.now();
    for (final schedule in schedules) {
      if (schedule.dayOfWeek != now.weekday) {
        continue;
      }
      final start = _toMinutes(schedule.startTime);
      final end = _toMinutes(schedule.endTime);
      final current = now.hour * 60 + now.minute;
      if (current >= start && current < end) {
        return true;
      }
    }
    return false;
  }

  Widget _buildMascotStatusBanner(_TimetableMascotState state) {
    final labels = {
      _TimetableMascotState.studyBurn: '수업 집중 모드',
      _TimetableMascotState.classNodding: '수업 끄덕끄덕 모드',
      _TimetableMascotState.reading: '공강 독서 모드',
      _TimetableMascotState.campusWalk: '공강 캠퍼스 산책 모드',
      _TimetableMascotState.waving: '일정 등록 성공!',
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildTimetableMascotAsset(
              candidates: _timetableMascotCandidates[state]!,
              width: 92,
              height: 92,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labels[state]!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setTemporaryMascotState(
    _TimetableMascotState state,
    Duration duration,
  ) {
    _mascotTimer?.cancel();
    setState(() {
      _forcedMascotState = state;
    });
    _mascotTimer = Timer(duration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _forcedMascotState = null;
      });
    });
  }

  Future<void> _openQuickActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('수동 일정 추가'),
                onTap: () => Navigator.of(context).pop('manual'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 OCR 가져오기'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('카메라로 OCR 가져오기'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) {
      return;
    }

    if (action == 'manual') {
      await _openScheduleForm();
      return;
    }

    if (action == 'gallery') {
      await _importFromImage(ImageSource.gallery);
      return;
    }

    if (action == 'camera') {
      await _importFromImage(ImageSource.camera);
    }
  }

  Future<void> _importFromImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null || !mounted) {
      return;
    }

    final apiKey = await _promptApiKey();
    if (apiKey == null || apiKey.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      await ref
          .read(scheduleListProvider.notifier)
          .importFromTimetableImagePath(imagePath: picked.path, apiKey: apiKey);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OCR 시간표 반영 완료!')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('OCR 처리 실패: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<String?> _promptApiKey() async {
    _apiKeyController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gemini API Key 입력'),
          content: TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(labelText: 'API Key'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_apiKeyController.text.trim()),
              child: const Text('가져오기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openScheduleDetailDialog(Schedule schedule) async {
    final confirmedDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(schedule.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_dayLabelFull(schedule.dayOfWeek)} ${schedule.startTime} ~ ${schedule.endTime}',
              ),
              const SizedBox(height: 8),
              Text(schedule.location?.trim().isNotEmpty == true
                  ? schedule.location!
                  : '장소/메모 없음'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmedDelete != true || !mounted) {
      return;
    }

    if (schedule.id == null || schedule.id! < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('샘플 일정은 삭제할 수 없어요.')));
      return;
    }

    await ref.read(scheduleListProvider.notifier).deleteSchedule(schedule.id!);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('일정이 삭제되었습니다.')));
  }

  Future<void> _openScheduleForm({Schedule? initial}) async {
    final result = await showDialog<Schedule>(
      context: context,
      builder: (context) => ScheduleFormDialog(initial: initial),
    );

    if (result == null) {
      return;
    }

    if (result.id == null) {
      await ref.read(scheduleListProvider.notifier).addSchedule(result);
      if (!mounted) {
        return;
      }
      _setTemporaryMascotState(
        _TimetableMascotState.waving,
        const Duration(milliseconds: 1600),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 일정 등록 완료! 삼순이가 반겨요.')));
    } else {
      await ref.read(scheduleListProvider.notifier).updateSchedule(result);
    }
  }

  List<Schedule> get _mockSchedules => const [
    Schedule(
      id: -11,
      title: '컴퓨터개론',
      type: ScheduleType.classType,
      dayOfWeek: 1,
      startTime: '09:00',
      endTime: '10:30',
      location: 'A동 201',
      isCompleted: false,
      alarmOffsetMinutes: 30,
    ),
    Schedule(
      id: -12,
      title: '프로그래밍 기초',
      type: ScheduleType.classType,
      dayOfWeek: 2,
      startTime: '13:00',
      endTime: '14:30',
      location: 'B동 303',
      isCompleted: false,
      alarmOffsetMinutes: 60,
    ),
    Schedule(
      id: -13,
      title: '컴퓨터교육론',
      type: ScheduleType.classType,
      dayOfWeek: 4,
      startTime: '15:00',
      endTime: '16:30',
      location: '사범대 105',
      isCompleted: false,
      alarmOffsetMinutes: 30,
    ),
  ];

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return 9 * 60;
    }
    return (int.tryParse(parts[0]) ?? 9) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  Color _pastelColorFor(int seed) {
    final palette = [
      const Color(0xFFEDE7F6),
      const Color(0xFFE3F2FD),
      const Color(0xFFE0F2F1),
      const Color(0xFFFFF3E0),
      const Color(0xFFFCE4EC),
      const Color(0xFFE8F5E9),
    ];
    return palette[seed.abs() % palette.length];
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

  String _dayLabelFull(int value) {
    switch (value) {
      case 1:
        return '월요일';
      case 2:
        return '화요일';
      case 3:
        return '수요일';
      case 4:
        return '목요일';
      case 5:
        return '금요일';
      case 6:
        return '토요일';
      case 7:
        return '일요일';
      default:
        return '요일 미정';
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
