import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class SignIn implements UseCase<AppUser, SignInParams> {
  const SignIn(this._repository);
  final AuthRepository _repository;

  @override
  Future<AppUser> call(SignInParams p) =>
      _repository.signIn(email: p.email.trim(), password: p.password);
}

class SignUp implements UseCase<SignUpOutcome, SignUpParams> {
  const SignUp(this._repository);
  final AuthRepository _repository;

  @override
  Future<SignUpOutcome> call(SignUpParams p) => _repository.signUp(
    name: p.name.trim(),
    email: p.email.trim(),
    password: p.password,
  );
}

class SignOut implements UseCase<void, NoParams> {
  const SignOut(this._repository);
  final AuthRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.signOut();
}

class GetCurrentUser implements UseCase<AppUser?, NoParams> {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<AppUser?> call(NoParams params) async => _repository.currentUser;
}
