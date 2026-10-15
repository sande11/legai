import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Stores settings in SharedPreferences.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _theme = 'settings.theme';
  static const _jurisdiction = 'settings.jurisdiction';
  static const _announce = 'settings.announceRecording';
  static const _whisper = 'settings.whisperAdvice';

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings();
    final themeName = _prefs.getString(_theme);
    return AppSettings(
      theme: ThemePreference.values.firstWhere(
        (t) => t.name == themeName,
        orElse: () => defaults.theme,
      ),
      jurisdictionCode:
          _prefs.getString(_jurisdiction) ?? defaults.jurisdictionCode,
      announceRecording:
          _prefs.getBool(_announce) ?? defaults.announceRecording,
      whisperAdvice: _prefs.getBool(_whisper) ?? defaults.whisperAdvice,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setString(_theme, settings.theme.name),
      _prefs.setString(_jurisdiction, settings.jurisdictionCode),
      _prefs.setBool(_announce, settings.announceRecording),
      _prefs.setBool(_whisper, settings.whisperAdvice),
    ]);
  }
}
