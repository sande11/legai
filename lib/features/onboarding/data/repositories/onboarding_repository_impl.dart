import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  // Same key the app used before, so people who already onboarded skip it.
  static const _key = 'isFirstTime';

  @override
  Future<bool> isFirstLaunch() async => _prefs.getBool(_key) ?? true;

  @override
  Future<void> completeOnboarding() => _prefs.setBool(_key, false);
}
