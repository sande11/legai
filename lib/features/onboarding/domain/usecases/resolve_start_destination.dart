import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/onboarding_repository.dart';

enum StartDestination { onboarding, login, home }

/// Decides where the app opens: first-time onboarding, login, or home.
class ResolveStartDestination implements UseCase<StartDestination, NoParams> {
  const ResolveStartDestination(this._onboarding, this._auth);

  final OnboardingRepository _onboarding;
  final AuthRepository _auth;

  @override
  Future<StartDestination> call(NoParams params) async {
    if (await _onboarding.isFirstLaunch()) return StartDestination.onboarding;
    if (!_auth.requiresSignIn || _auth.currentUser != null) {
      return StartDestination.home;
    }
    return StartDestination.login;
  }
}

class CompleteOnboarding implements UseCase<StartDestination, NoParams> {
  const CompleteOnboarding(this._onboarding, this._auth);

  final OnboardingRepository _onboarding;
  final AuthRepository _auth;

  /// Marks onboarding done and returns where to go next.
  @override
  Future<StartDestination> call(NoParams params) async {
    await _onboarding.completeOnboarding();
    return (!_auth.requiresSignIn || _auth.currentUser != null)
        ? StartDestination.home
        : StartDestination.login;
  }
}
