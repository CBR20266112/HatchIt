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
import '../schedules/presentation/schedule_controller.dart';
import '../schedules/presentation/widgets/timetable_screen.dart';
import '../daily_records/presentation/daily_record_controller.dart';

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

  Future<bool> _showDeveloperPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('개발자 옵션 잠금'),
            content: TextField(
              controller: passwordController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '숫자 8자리 입력',
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(value == '20266112');
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(passwordController.text == '20266112');
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _resetAppDataFromSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text(
            '모든 일정, 알 성장 기록, 재화가 초기화됩니다. 계속하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref.read(scheduleListProvider.notifier).clearAllSchedules();
    await ref.read(dailyRecordControllerProvider).clearAllRecords();
    await ref.read(mascotProfileProvider.notifier).resetForAppDataClear();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('앱이 초기 상태로 리셋되었습니다.')));
    Navigator.of(context).pop();
  }

  Future<void> _openSettingsSheet() async {
    if (!mounted) {
      return;
    }
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
        var geminiApiKeyDraft = '';
        var geminiDraftInitialized = false;
        var geminiSaving = false;
        String? geminiStatusMessage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer(
              builder: (context, ref, _) {
                final settings = ref.watch(settingsControllerProvider);
                if (!geminiDraftInitialized) {
                  geminiApiKeyDraft = settings.geminiApiKey;
                  geminiDraftInitialized = true;
                }
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
                                onTap: () async {
                                  if (showDeveloperOptions) {
                                    setSheetState(() {
                                      showDeveloperOptions = false;
                                    });
                                    return;
                                  }

                                  final authorized =
                                      await _showDeveloperPasswordDialog(context);
                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (!authorized) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('꺼져!')),
                                    );
                                    Navigator.of(context).pop();
                                    return;
                                  }

                                  setSheetState(() {
                                    showDeveloperOptions = true;
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
                        const SizedBox(height: 18),
                        Text(
                          'Gemini',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: geminiSaving
                                ? null
                                : () async {
                                    final keyController = TextEditingController(
                                      text: geminiApiKeyDraft,
                                    );
                                    final nextKey = await showModalBottomSheet<String>(
                                      context: context,
                                      isScrollControlled: true,
                                      showDragHandle: true,
                                      builder: (sheetContext) {
                                        var obscureKey = true;
                                        return StatefulBuilder(
                                          builder: (sheetContext, setModalState) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                top: 12,
                                                bottom:
                                                    MediaQuery.of(sheetContext)
                                                        .viewInsets
                                                        .bottom +
                                                    20,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Gemini 키 설정',
                                                          style: Theme.of(
                                                            sheetContext,
                                                          ).textTheme.titleMedium,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: '가이드 보기',
                                                        onPressed: () {
                                                          showDialog<void>(
                                                            context: sheetContext,
                                                            builder: (
                                                              guideContext,
                                                            ) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                  'Gemini 키 가이드',
                                                                ),
                                                                content: const Text(
                                                                  '1) 먼저 브라우저에서 https://aistudio.google.com 에 접속해요.\n'
                                                                  '   (구글 로그인 필요)\n'
                                                                  '2) 상단/좌측의 Get API key 메뉴에서 키를 발급받아요.\n'
                                                                  '3) 발급받은 키를 여기 입력창에 붙여넣고 저장해요.\n'
                                                                  '4) 저장 후 비서실(...) 버튼으로 자연어 명령을 실행해요.\n\n'
                                                                  '주의: API 키는 비밀번호처럼 취급하고 공유하지 마세요.',
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(
                                                                        guideContext,
                                                                      ).pop();
                                                                    },
                                                                    child: const Text(
                                                                      '확인',
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.help_outline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: keyController,
                                                    obscureText: obscureKey,
                                                    decoration: InputDecoration(
                                                      labelText: 'Gemini API Key',
                                                      hintText:
                                                          'AIza... 형식 키 입력',
                                                      border:
                                                          const OutlineInputBorder(),
                                                      suffixIcon: IconButton(
                                                        onPressed: () {
                                                          setModalState(() {
                                                            obscureKey =
                                                                !obscureKey;
                                                          });
                                                        },
                                                        icon: Icon(
                                                          obscureKey
                                                              ? Icons
                                                                    .visibility_off_rounded
                                                              : Icons
                                                                    .visibility_rounded,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              sheetContext,
                                                            ).pop();
                                                          },
                                                          child: const Text('취소'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: FilledButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              sheetContext,
                                                            ).pop(
                                                              keyController.text
                                                                  .trim(),
                                                            );
                                                          },
                                                          child: const Text('저장'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                    keyController.dispose();

                                    if (nextKey == null) {
                                      return;
                                    }

                                    geminiApiKeyDraft = nextKey;
                                    setSheetState(() {
                                      geminiSaving = true;
                                      geminiStatusMessage = 'Gemini 키 저장 중...';
                                    });
                                    await ref
                                        .read(settingsControllerProvider.notifier)
                                        .setGeminiApiKey(nextKey);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    setSheetState(() {
                                      geminiSaving = false;
                                      geminiStatusMessage = '저장 완료 ✅';
                                    });
                                  },
                            icon: geminiSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.key_rounded),
                            label: const Text('Gemini 버튼 열기'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          geminiStatusMessage ??
                              'Gemini 버튼 → ? 순서로 누르면 어디서 키를 만드는지부터 안내해요.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onPressed: _resetAppDataFromSettings,
                            icon: const Icon(Icons.delete_forever_rounded),
                            label: const Text('데이터 초기화'),
                          ),
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
