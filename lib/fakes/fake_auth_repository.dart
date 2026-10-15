import 'package:shared_preferences/shared_preferences.dart';

import '../core/error/failures.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

/// Sign-in that always works. Any email and a 6+ character password log in;
/// the "account" is remembered on the phone until you log out.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(
    this._prefs, {
    this.delay = const Duration(milliseconds: 700),
  });

  final SharedPreferences _prefs;
  final Duration delay;

  static const _emailKey = 'fakes.user.email';
  static const _nameKey = 'fakes.user.name';

  @override
  bool get requiresSignIn => true;

  @override
  AppUser? get currentUser {
    final email = _prefs.getString(_emailKey);
    if (email == null) return null;
    return AppUser(
      id: 'demo-user',
      email: email,
      name: _prefs.getString(_nameKey),
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    if (email.trim().isEmpty || password.length < 6) {
      throw const AuthFailure(
        'The email or password you entered is incorrect.',
      );
    }
    await _prefs.setString(_emailKey, email.trim());
    return currentUser!;
  }

  @override
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    await _prefs.setString(_emailKey, email.trim());
    if (name.trim().isNotEmpty) await _prefs.setString(_nameKey, name.trim());
    return SignUpOutcome.signedIn;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_emailKey);
    await _prefs.remove(_nameKey);
  }
}
