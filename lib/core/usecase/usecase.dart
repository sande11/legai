/// A single application action, e.g. "ask a legal question".
///
/// Use cases depend only on domain repositories, so the presentation layer
/// never talks to data sources directly.
abstract interface class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

/// For use cases that take no input.
class NoParams {
  const NoParams();
}
