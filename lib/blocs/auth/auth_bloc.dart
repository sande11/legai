import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legai/blocs/auth/auth_error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, MyAuthState> {
  final SupabaseClient supabase;

  AuthBloc({required this.supabase}) : super(MyAuthInitial()) {
    // When user tries to sign in
    on<SignInRequested>((event, emit) async {
  emit(MyAuthLoading());
  try {
    final response = await supabase.auth.signInWithPassword(
      email: event.email,
      password: event.password,
    );
    
    if (response.user?.emailConfirmedAt == null) {
      emit(MyAuthError('Please verify your email before logging in'));
    } else if (response.user != null) {
      emit(MyAuthAuthenticated());
    }
  } on AuthException catch (e) {
    emit(MyAuthError(AuthErrorHandler.getFriendlyMessage(e.message)));
  } catch (e) {
    emit(MyAuthError(AuthErrorHandler.getFriendlyMessage(e.toString())));
  }
});

    // When user tries to sign up
    on<SignUpRequested>((event, emit) async {
      emit(MyAuthLoading());
      try {
        final response = await supabase.auth.signUp(
          email: event.email,
          password: event.password,
          // You can add user metadata here if needed, e.g. name
        );
        if (response.user != null) {
          emit(MyAuthAuthenticated());
        } else {
          emit(MyAuthError('Sign up failed'));
        }
      } catch (e) {
        emit(MyAuthError(e.toString()));
      }
    });

    // When user signs out
    on<SignOutRequested>((event, emit) async {
      await supabase.auth.signOut();
      emit(MyAuthUnauthenticated());
    });
  }
}