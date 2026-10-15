import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/settings_usecases.dart';

/// App-wide settings. Provided at the root so the theme and jurisdiction
/// update everywhere at once.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit({
    required LoadSettings loadSettings,
    required SaveSettings saveSettings,
  }) : _load = loadSettings,
       _save = saveSettings,
       super(const AppSettings());

  final LoadSettings _load;
  final SaveSettings _save;

  Future<void> load() async => emit(await _load(const NoParams()));

  ThemeMode get themeMode => switch (state.theme) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  Future<void> setTheme(ThemePreference theme) =>
      _update(state.copyWith(theme: theme));
  Future<void> setJurisdiction(String code) =>
      _update(state.copyWith(jurisdictionCode: code));
  Future<void> setAnnounceRecording(bool on) =>
      _update(state.copyWith(announceRecording: on));
  Future<void> setWhisperAdvice(bool on) =>
      _update(state.copyWith(whisperAdvice: on));

  Future<void> _update(AppSettings next) async {
    emit(next);
    await _save(next);
  }
}
