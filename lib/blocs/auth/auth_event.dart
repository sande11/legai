import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// user wants to sign in
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

// user wants to sign up
class SignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  SignUpRequested(this.name, this.email, this.password);
  @override
  List<Object?> get props => [name, email, password];
}

//user wants to sign out 
class SignOutRequested extends AuthEvent {
  @override
  List<Object?> get props => [];
}


