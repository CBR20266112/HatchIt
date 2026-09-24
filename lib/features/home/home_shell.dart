import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions/alarm_permission_service.dart';
import '../../core/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../events/presentation/cat_ambush_controller.dart';
import '../events/presentation/cat_ambush_dialog.dart';
import '../mascot/domain/mascot_species.dart';
import '../mascot/presentation/mascot_controller.dart';
import '../mascot/presentation/mascot_hub_screen.dart';
import '../minigame/presentation/campus_minigame_screen.dart';
import '../mission/presentation/mission_alarm_screen.dart';
import '../schedules/presentation/widgets/timetable_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _developerToggleAssetPath = 'assets/images/ui/dev_toggle.png';

  int _index = 0;
  int _lastHandledCatEventId = 0;
  final _alarmPermissionService = AlarmPermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      ref.read(catAmbushControllerProvider.notifier).start();
      await _alarmPermissionService.ensureAlarmPermissions(context);
    });
  }

  Future<void> _handleCatAmbush() async {
    final result = await showDialog<CatAmbushResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CatAmbushDialog(),
    );

    if (result == null) {
      ref
          .read(catAmbushControllerProvider.notifier)
          .resolve(success: false, taps: 0);
      return;
    }

    await ref
        .read(mascotProfileProvider.notifier)
        .grantMiniGameRewards(
          exp: result.rewardExp,
          furBalls: result.rewardFurBalls,
          keycaps: result.rewardKeycaps,
        );

    if (mounted) {
      final text = result.success
          ? '길냥이 이벤트 성공! 털뭉치 +${result.rewardFurBalls}, 키캡 +${result.rewardKeycaps}, EXP +${result.rewardExp}'
          : '길냥이가 도망갔어요. 위로 EXP +${result.rewardExp}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }

    ref
        .read(catAmbushControllerProvider.notifier)
        .resolve(success: result.success, taps: result.tapCount);
  }

  Future<void> _openSettingsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final initialSpeciesId =
        ref.read(mascotProfileProvider).valueOrNull?.speciesId ?? 16;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        var showDeveloperOptions = false;
        var isDeveloperBusy = false;
        var wipeEconomyOnReset = false;
        var selectedDeveloperSpeciesId = initialSpeciesId;
        var hatchWhenApplyingSpecies = true;
        String? developerStatusMessage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer(
              builder: (context, ref, _) {
                final settings = ref.watch(settingsControllerProvider);
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '설정',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Tooltip(
                              message: '개발자 옵션 토글',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setSheetState(() {
                                    showDeveloperOptions = !showDeveloperOptions;
                                  });
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      _developerToggleAssetPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          alignment: Alignment.center,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          child: const Icon(
                                            Icons.developer_mode_rounded,
                                            size: 16,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showDeveloperOptions) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer.withValues(alpha: 0.6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '개발자 옵션 · 마스코트 테스트',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  developerStatusMessage ??
                                      '빠른 테스트용: 즉시 부화 / 쿨타임 리셋 / 알 재지급',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<int>(
                                  initialValue: selectedDeveloperSpeciesId,
                                  decoration: const InputDecoration(
                                    labelText: '강제 캐릭터 선택',
                                  ),
                                  items: MascotSpeciesDefinition.all
                                      .map(
                                        (species) => DropdownMenuItem<int>(
                                          value: species.id,
                                          child: Text(
                                            '${species.id}. ${species.name} (${species.nickname})',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: isDeveloperBusy
                                      ? null
                                      : (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setSheetState(() {
                                            selectedDeveloperSpeciesId = value;
                                          });
                                        },
                                ),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: hatchWhenApplyingSpecies,
                                  onChanged: isDeveloperBusy
                                      ? null
                                      : (value) {
                                          setSheetState(() {
                                            hatchWhenApplyingSpecies = value ?? true;
                                          });
                                        },
                                  title: const Text('선택 캐릭터 적용 시 즉시 부화'),
                                  subtitle: const Text('끄면 알 상태는 유지하고 species만 교체'),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: isDeveloperBusy
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              isDeveloperBusy = true;
                                              developerStatusMessage =
                                                  '선택 캐릭터 적용 중...';
                                            });
                                            await ref
                                                .read(
                                                  mascotProfileProvider.notifier,
                                                )
                                                .developerSetSpecies(
                                                  selectedDeveloperSpeciesId,
                                                  hatchIfEgg:
                                                      hatchWhenApplyingSpecies,
                                                );
                                            if (!context.mounted) {
                                              return;
                                            }
                                            final selected =
                                                MascotSpeciesDefinition.byId(
                                                  selectedDeveloperSpeciesId,
                                                );
                                            setSheetState(() {
                                              isDeveloperBusy = false;
                                              developerStatusMessage =
                                                  '완료: ${selected.name}(${selected.nickname}) 적용';
                                            });
                                          },
                                    icon: const Icon(Icons.palette_rounded),
                                    label: const Text('선택 캐릭터 적용'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: isDeveloperBusy
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              isDeveloperBusy = true;
                                              developerStatusMessage =
                                                  '알 즉시 부화 적용 중...';
                                            });
                                            await ref
                                                .read(
                                                  mascotProfileProvider.notifier,
                                                )
                                                .developerInstantHatch();
                                            if (!context.mounted) {
                                              return;
                                            }
                                            setSheetState(() {
                                              isDeveloperBusy = false;
                                              developerStatusMessage =
                                                  '완료: 현재 알이 즉시 부화 상태로 변경됐습니다.';
                                            });
                                          },
                                    icon: const Icon(Icons.auto_fix_high_rounded),
                                    label: const Text('알 즉시 부화'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: isDeveloperBusy
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              isDeveloperBusy = true;
                                              developerStatusMessage =
                                                  '쿨타임 초기화 중...';
                                            });
                                            await ref
                                                .read(
                                                  mascotProfileProvider.notifier,
                                                )
                                                .developerResetCooldowns();
                                            if (!context.mounted) {
                                              return;
                                            }
                                            setSheetState(() {
                                              isDeveloperBusy = false;
                                              developerStatusMessage =
                                                  '완료: 쓰다듬기/밥주기 쿨타임이 즉시 리셋됐습니다.';
                                            });
                                          },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('쿨타임 리셋'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: wipeEconomyOnReset,
                                  onChanged: isDeveloperBusy
                                      ? null
                                      : (value) {
                                          setSheetState(() {
                                            wipeEconomyOnReset = value ?? false;
                                          });
                                        },
                                  title: const Text('알 재지급 시 재화도 함께 초기화'),
                                  subtitle: const Text('EXP / Fur Balls / Keycaps를 0으로 리셋'),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: isDeveloperBusy
                                        ? null
                                        : () async {
                                            setSheetState(() {
                                              isDeveloperBusy = true;
                                              developerStatusMessage =
                                                  'AI 비서 초기화 및 알 재지급 처리 중...';
                                            });
                                            await ref
                                                .read(
                                                  mascotProfileProvider.notifier,
                                                )
                                                .developerResetToEgg(
                                                  resetEconomy: wipeEconomyOnReset,
                                                );
                                            if (!context.mounted) {
                                              return;
                                            }
                                            setSheetState(() {
                                              isDeveloperBusy = false;
                                              developerStatusMessage =
                                                  '완료: 캐릭터 초기화 후 다시 해치 가능한 알 상태로 복귀했습니다.';
                                            });
                                          },
                                    icon: const Icon(Icons.egg_alt_outlined),
                                    label: const Text('AI 비서 초기화 + 알 재지급'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          '테마 모드',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.themeSystem),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.themeDark),
                            ),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (next) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .setThemeMode(next.first);
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.language,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'ko', label: Text('한국어(ko)')),
                            ButtonSegment(value: 'en', label: Text('English(en)')),
                          ],
                          selected: {settings.localeCode},
                          onSelectionChanged: (next) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .setLocaleCode(next.first);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CatAmbushState>(catAmbushControllerProvider, (previous, next) {
      if (!next.isActive || !mounted) {
        return;
      }
      if (_lastHandledCatEventId == next.eventId) {
        return;
      }
      _lastHandledCatEventId = next.eventId;
      _handleCatAmbush();
    });

    final pages = [
      MascotHubScreen(onOpenSettings: _openSettingsSheet),
      const TimetableScreen(),
      const MissionAlarmScreen(),
      const CampusMiniGameScreen(),
    ];

    const appBarTitles = ['비서실', '해칫 시간표', '기상 & 미션', '캠퍼스 오락실'];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_index]),
        actions: [
          IconButton(
            tooltip: '설정',
            onPressed: _openSettingsSheet,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          HapticFeedback.selectionClick();
          setState(() {
            _index = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_rounded),
            label: '비서실',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week_rounded),
            label: '해칫 시간표',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_rounded),
            label: '기상 & 미션',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_rounded),
            label: '캠퍼스 오락실',
          ),
        ],
      ),
    );
  }
}
