/// Route names. Pages navigate with `Navigator.pushNamed(context, Routes.x)`.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const history = '/history';
  static const settings = '/settings';
  static const chat = '/chat';
  static const voice = '/voice';
  static const listenSetup = '/listen/setup';
  static const listenLive = '/listen/live';
  static const review = '/listen/review';
}

/// Arguments for [Routes.chat].
class ChatArgs {
  const ChatArgs({this.conversationId, this.initialQuestion});

  /// Opens an existing conversation.
  final String? conversationId;

  /// Starts a new conversation by sending this question.
  final String? initialQuestion;
}

/// Arguments for [Routes.review].
class ReviewArgs {
  const ReviewArgs(this.sessionId);
  final String sessionId;
}
