import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/app_database.dart';
import 'core/settings/settings_controller.dart';
import 'features/alarm/alarm_service.dart';
import 'features/home/home_shell.dart';
import 'features/mascot/domain/mascot_species.dart';
import 'features/mascot/presentation/mascot_controller.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.initializeForPlatform();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await AndroidAlarmManager.initialize();
    } on MissingPluginException {
      // Running in environments where plugins are not attached (e.g. tests).
    } catch (error, stackTrace) {
      debugPrint('AndroidAlarmManager initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await AlarmService().initialize();
    } on MissingPluginException {
      // Running in environments where plugins are not attached (e.g. tests).
    } catch (error, stackTrace) {
      debugPrint('Local notification initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: HatchItApp()));
}

class HatchItApp extends ConsumerWidget {
  const HatchItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final mascotProfile = ref.watch(mascotProfileProvider).valueOrNull;
    final mascotPalette = MascotThemePalette.fromSpeciesId(
      mascotProfile?.speciesId,
    );

    return MaterialApp(
      title: 'HatchIt',
      debugShowCheckedModeBanner: false,
      locale: Locale(settings.localeCode),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.themeMode,
      theme: _buildHatchitTheme(
        Brightness.light,
        mascotPalette: mascotPalette,
      ),
      darkTheme: _buildHatchitTheme(
        Brightness.dark,
        mascotPalette: mascotPalette,
      ),
      home: const HomeShell(),
    );
  }
}

const _hatchitLightBackground = Color(0xFFF7F8FC);
const _hatchitLightSurface = Color(0xFFFFFFFF);

ThemeData _buildHatchitTheme(
  Brightness brightness, {
  required MascotThemePalette mascotPalette,
}) {
  final isDark = brightness == Brightness.dark;
  final themedPrimary = isDark
      ? Color.lerp(mascotPalette.primary, Colors.white, 0.18)!
      : mascotPalette.primary;
  final themedAccent = isDark
      ? Color.lerp(mascotPalette.accent, Colors.white, 0.12)!
      : mascotPalette.accent;
  final themedSurfaceTint = isDark
      ? Color.lerp(mascotPalette.surfaceTint, const Color(0xFF1E222D), 0.7)!
      : mascotPalette.surfaceTint;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: themedPrimary,
    onPrimary: Colors.white,
    secondary: themedAccent,
    onSecondary: Colors.white,
    error: const Color(0xFFE45858),
    onError: Colors.white,
    surface: isDark ? const Color(0xFF1E222D) : _hatchitLightSurface,
    onSurface: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF222432),
    surfaceContainerHighest: isDark
        ? const Color(0xFF282D3A)
        : const Color(0xFFEFF1F8),
    onSurfaceVariant: isDark
        ? const Color(0xFFC7CCD9)
        : const Color(0xFF4B5165),
    outline: isDark ? const Color(0xFF5E667A) : const Color(0xFFD9DDE8),
    outlineVariant: isDark ? const Color(0xFF3C4354) : const Color(0xFFE3E6EE),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF232634),
    onInverseSurface: isDark ? const Color(0xFF1D212D) : Colors.white,
    inversePrimary: isDark
        ? Color.lerp(themedPrimary, Colors.white, 0.3)!
        : Color.lerp(themedPrimary, Colors.black, 0.12)!,
    tertiary: isDark
        ? Color.lerp(mascotPalette.emotionHot, Colors.white, 0.2)!
        : mascotPalette.emotionHot,
    onTertiary: const Color(0xFF3D1F27),
    tertiaryContainer: isDark
        ? const Color(0xFF452737)
        : const Color(0xFFFFE3E8),
    onTertiaryContainer: isDark
        ? const Color(0xFFFFD9E1)
        : const Color(0xFF472232),
    surfaceDim: isDark ? const Color(0xFF12151D) : const Color(0xFFECEEF5),
    surfaceBright: isDark ? const Color(0xFF323847) : Colors.white,
    surfaceContainerLowest: isDark ? const Color(0xFF101318) : Colors.white,
    surfaceContainerLow: isDark
        ? const Color(0xFF1A1E29)
        : const Color(0xFFF8F9FD),
    surfaceContainer: isDark
        ? const Color(0xFF212634)
        : const Color(0xFFF4F6FB),
    surfaceContainerHigh: isDark
        ? const Color(0xFF292F3D)
        : const Color(0xFFF0F2F8),
    primaryContainer: isDark
        ? Color.lerp(themedPrimary, Colors.black, 0.45)!
        : Color.lerp(themedPrimary, Colors.white, 0.78)!,
    onPrimaryContainer: isDark
        ? const Color(0xFFFFD9DF)
        : const Color(0xFF4C1D28),
    secondaryContainer: isDark
        ? Color.lerp(themedAccent, Colors.black, 0.42)!
        : themedSurfaceTint,
    onSecondaryContainer: isDark
        ? const Color(0xFFE9E0FF)
        : const Color(0xFF2D1D5E),
  );

  return ThemeData(
    extensions: [mascotPalette],
    useMaterial3: true,
    splashFactory: InkRipple.splashFactory,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF13151B)
        : _hatchitLightBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      side: BorderSide.none,
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surfaceContainer,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
      brightness: brightness,
      disabledColor: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    textTheme:
        (isDark
                ? Typography.material2021(platform: defaultTargetPlatform).white
                : Typography.material2021(
                    platform: defaultTargetPlatform,
                  ).black)
            .apply(
              bodyColor: colorScheme.onSurface,
              displayColor: colorScheme.onSurface,
            )
            .copyWith(
              headlineSmall: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.25,
              ),
              titleMedium: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
              bodyMedium: const TextStyle(fontSize: 15, height: 1.45),
              bodySmall: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
  );
}
