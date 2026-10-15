import 'package:equatable/equatable.dart';

/// A failure the domain layer can show to the user.
///
/// Data sources throw exceptions; repositories catch them and rethrow a
/// [Failure] with a message that is safe to put on screen.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class SpeechUnavailableFailure extends Failure {
  const SpeechUnavailableFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class AssistantFailure extends Failure {
  const AssistantFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
