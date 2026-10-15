import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth_error_mapper.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  bool get requiresSignIn => true;

  @override
  AppUser? get currentUser {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user == null ? null : _map(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Something went wrong. Please try again.');
      }
      if (user.emailConfirmedAt == null) {
        throw const AuthFailure('Please confirm your email before logging in.');
      }
      return _map(user);
    } on Failure {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.friendly(e.message));
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.friendly(e.toString()));
    }
  }

  @override
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user == null) {
        throw const AuthFailure('Sign up failed. Please try again.');
      }
      return response.session != null
          ? SignUpOutcome.signedIn
          : SignUpOutcome.confirmationSent;
    } on Failure {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.friendly(e.message));
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.friendly(e.toString()));
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AppUser _map(sb.User user) => AppUser(
    id: user.id,
    email: user.email,
    name: user.userMetadata?['name'] as String?,
  );
}
