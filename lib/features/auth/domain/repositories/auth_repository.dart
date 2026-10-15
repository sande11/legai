import '../entities/app_user.dart';

/// Sign-up result: either signed in straight away, or waiting for the user
/// to confirm their email.
enum SignUpOutcome { signedIn, confirmationSent }

abstract interface class AuthRepository {
  /// False when the app runs in guest mode without a backend.
  bool get requiresSignIn;

  AppUser? get currentUser;

  /// Throws [AuthFailure] with a friendly message.
  Future<AppUser> signIn({required String email, required String password});

  /// Throws [AuthFailure] with a friendly message.
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
