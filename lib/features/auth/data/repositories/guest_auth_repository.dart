import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Used when no Supabase keys are configured, so the app still runs
/// end to end on a device or simulator. Everyone is a local guest.
class GuestAuthRepository implements AuthRepository {
  static const _guest = AppUser(id: 'guest', isGuest: true);

  @override
  bool get requiresSignIn => false;

  @override
  AppUser? get currentUser => _guest;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _guest;

  @override
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async => SignUpOutcome.signedIn;

  @override
  Future<void> signOut() async {}
}
