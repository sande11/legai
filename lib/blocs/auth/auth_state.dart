import 'package:equatable/equatable.dart';

abstract class MyAuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyAuthInitial extends MyAuthState {}

class MyAuthAuthenticated extends MyAuthState {}

class MyAuthUnauthenticated extends MyAuthState {}

class MyAuthLoading extends MyAuthState {}

class MyAuthError extends MyAuthState {
  final String message;
  MyAuthError(this.message);
  @override
  List<Object?> get props => [message];
}
