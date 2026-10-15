import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// Events ---------------------------------------------------------------------

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  const SignInRequested(this.email, this.password);
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  const SignUpRequested(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [name, email, password];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

// States ---------------------------------------------------------------------

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppUser user;
  @override
  List<Object?> get props => [user];
}

class AuthConfirmationSent extends AuthState {
  const AuthConfirmationSent(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// Bloc -----------------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._signIn,
    required this._signUp,
    required this._signOut,
  }) : super(const AuthInitial()) {
    on<SignInRequested>(_onSignIn);
    on<SignUpRequested>(_onSignUp);
    on<SignOutRequested>(_onSignOut);
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;

  Future<void> _onSignIn(SignInRequested e, Emitter<AuthState> emit) async {
    if (e.email.trim().isEmpty || e.password.isEmpty) {
      emit(const AuthError('Please enter your email and password.'));
      return;
    }
    emit(const AuthLoading());
    try {
      final user = await _signIn(
        SignInParams(email: e.email, password: e.password),
      );
      emit(AuthAuthenticated(user));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onSignUp(SignUpRequested e, Emitter<AuthState> emit) async {
    if (e.email.trim().isEmpty || e.password.isEmpty) {
      emit(const AuthError('Please enter your email and a password.'));
      return;
    }
    emit(const AuthLoading());
    try {
      final outcome = await _signUp(
        SignUpParams(name: e.name, email: e.email, password: e.password),
      );
      if (outcome == SignUpOutcome.confirmationSent) {
        emit(AuthConfirmationSent(e.email.trim()));
      } else {
        emit(
          AuthAuthenticated(
            AppUser(id: '', email: e.email.trim(), name: e.name.trim()),
          ),
        );
      }
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onSignOut(SignOutRequested e, Emitter<AuthState> emit) async {
    await _signOut(const NoParams());
    emit(const AuthUnauthenticated());
  }
}
