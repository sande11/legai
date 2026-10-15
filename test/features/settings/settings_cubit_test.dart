import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:legai/features/settings/domain/entities/app_settings.dart';
import 'package:legai/features/settings/domain/usecases/settings_usecases.dart';
import 'package:legai/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('settings persist across launches', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepositoryImpl(prefs);
    final cubit = SettingsCubit(
      loadSettings: LoadSettings(repo),
      saveSettings: SaveSettings(repo),
    );

    await cubit.load();
    expect(cubit.state, const AppSettings());
    expect(cubit.themeMode, ThemeMode.system);

    await cubit.setTheme(ThemePreference.dark);
    await cubit.setJurisdiction('KE');
    await cubit.setWhisperAdvice(false);

    final reloaded = SettingsCubit(
      loadSettings: LoadSettings(repo),
      saveSettings: SaveSettings(repo),
    );
    await reloaded.load();
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.state.jurisdiction.name, 'Kenya');
    expect(reloaded.state.whisperAdvice, isFalse);
    expect(reloaded.state.announceRecording, isTrue);
  });
}
