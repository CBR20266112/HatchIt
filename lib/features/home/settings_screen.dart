import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_controller.dart';
import '../daily_records/presentation/daily_record_controller.dart';
import '../mascot/domain/mascot_species.dart';
import '../mascot/presentation/mascot_controller.dart';

/// 개발자 옵션 비밀번호 입력 팝업
Future<bool> showDeveloperPasswordDialog(BuildContext context) async {
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
              Navigator.of(dialogContext).pop(value.trim() == '20266112');
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(passwordController.text.trim() == '20266112');
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

/// 설정 화면 (단독 스크린 및 모달 지원)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var isDeveloperBusy = false;
  var wipeEconomyOnReset = false;
  var hatchWhenApplyingSpecies = true;
  String? developerStatusMessage;
  var geminiApiKeyDraft = '';
  var geminiDraftInitialized = false;
  var geminiSaving = false;
  String? geminiStatusMessage;
  int selectedDeveloperSpeciesId = 16;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(mascotProfileProvider).valueOrNull;
    if (profile?.speciesId != null) {
      selectedDeveloperSpeciesId = profile!.speciesId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final isDeveloperMode = ref.watch(developerModeProvider);

    if (!geminiDraftInitialized) {
      geminiApiKeyDraft = settings.geminiApiKey;
      geminiDraftInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
          IconButton(
            tooltip: '개발자 옵션 토글',
            icon: Icon(
              isDeveloperMode
                  ? Icons.developer_mode_rounded
                  : Icons.code_rounded,
            ),
            onPressed: () async {
              if (isDeveloperMode) {
                ref.read(developerModeProvider.notifier).state = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('개발자 옵션이 비활성화되었습니다.')),
                );
                return;
              }

              final authorized = await showDeveloperPasswordDialog(context);
              if (!context.mounted) return;

              if (!authorized) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호가 올바르지 않습니다')),
                );
                return;
              }

              ref.read(developerModeProvider.notifier).state = true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('개발자 모드가 활성화되었습니다.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // 테마 모드
          Text('화면 테마', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('시스템'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('라이트'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('다크'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .setThemeMode(value.first);
            },
          ),
          const SizedBox(height: 20),

          // Gemini API 키 설정
          Text('Gemini API 설정', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: geminiApiKeyDraft),
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'AI 비서 기능을 위한 API 키 입력',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => geminiApiKeyDraft = val,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: geminiSaving
                ? null
                : () async {
                    setState(() => geminiSaving = true);
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .setGeminiApiKey(geminiApiKeyDraft);
                    if (mounted) {
                      setState(() {
                        geminiSaving = false;
                        geminiStatusMessage = 'API 키가 저장되었습니다.';
                      });
                    }
                  },
            child: const Text('API 키 저장'),
          ),
          if (geminiStatusMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              geminiStatusMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // 개발자 옵션 섹션
          if (isDeveloperMode) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.developer_mode_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '개발자 옵션',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selectedDeveloperSpeciesId,
              decoration: const InputDecoration(
                labelText: '마스코트 종 변경',
                border: OutlineInputBorder(),
              ),
              items: List.generate(16, (i) => i + 1).map((id) {
                final def = MascotSpeciesDefinition.byId(id);
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text('${def.id}. ${def.name} (${def.nickname})'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedDeveloperSpeciesId = val);
                }
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('종 변경 시 즉시 부화'),
              value: hatchWhenApplyingSpecies,
              onChanged: (val) =>
                  setState(() => hatchWhenApplyingSpecies = val ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            FilledButton.tonal(
              onPressed: isDeveloperBusy
                  ? null
                  : () async {
                      setState(() => isDeveloperBusy = true);
                      await ref
                          .read(mascotProfileProvider.notifier)
                          .developerSetSpecies(
                            selectedDeveloperSpeciesId,
                            hatchIfEgg: hatchWhenApplyingSpecies,
                          );
                      if (mounted) {
                        setState(() {
                          isDeveloperBusy = false;
                          developerStatusMessage = '마스코트가 변경되었습니다.';
                        });
                      }
                    },
              child: const Text('마스코트 종 적용'),
            ),
            const SizedBox(height: 12),
            // 개발자 치트 1: [⏩ 부화 일자 +1일 진행]
            FilledButton.tonalIcon(
              onPressed: isDeveloperBusy
                  ? null
                  : () async {
                      setState(() => isDeveloperBusy = true);
                      await ref
                          .read(mascotProfileProvider.notifier)
                          .developerAdvanceEggDay();
                      if (mounted) {
                        setState(() {
                          isDeveloperBusy = false;
                          developerStatusMessage =
                              '⏩ 부화 일자 +1일 진행 완료 (Day 7 도달 시 자동 부화)';
                        });
                      }
                    },
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('⏩ 부화 일자 +1일 진행'),
            ),
            const SizedBox(height: 8),
            // 개발자 치트 2: [⏱️ 모든 쿨타임 즉시 초기화]
            FilledButton.tonalIcon(
              onPressed: isDeveloperBusy
                  ? null
                  : () async {
                      setState(() => isDeveloperBusy = true);
                      await ref
                          .read(mascotProfileProvider.notifier)
                          .developerResetCooldowns();
                      await ref
                          .read(dailyRecordControllerProvider)
                          .clearAllRecords();
                      if (mounted) {
                        setState(() {
                          isDeveloperBusy = false;
                          developerStatusMessage =
                              '⏱️ 모든 쿨타임(밥·쓰다듬기·빗질·일일 퀘스트) 즉시 초기화 완료!';
                        });
                      }
                    },
              icon: const Icon(Icons.timer_off_rounded),
              label: const Text('⏱️ 모든 쿨타임 즉시 초기화'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isDeveloperBusy
                  ? null
                  : () async {
                      setState(() => isDeveloperBusy = true);
                      await ref
                          .read(mascotProfileProvider.notifier)
                          .developerInstantHatch();
                      if (mounted) {
                        setState(() {
                          isDeveloperBusy = false;
                          developerStatusMessage = '즉시 부화 처리되었습니다.';
                        });
                      }
                    },
              child: const Text('즉시 부화 (Instant Hatch)'),
            ),
            if (developerStatusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                developerStatusMessage!,
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ],
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),
          // 앱 데이터 전체 초기화 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('앱 데이터 전체 초기화'),
                    content: const Text(
                      '모든 일정, 알 및 마스코트 기록, 재화, 다운로드된 에셋, 설정이 완전 삭제됩니다.\n계속하시겠습니까?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                        ),
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        child: const Text('전체 초기화'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await executeFullAppReset(context, ref);
                }
              },
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('앱 데이터 전체 초기화'),
            ),
          ),
        ],
      ),
    );
  }
}
