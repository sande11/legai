import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/pages/history_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/listen_in/presentation/cubit/listen_setup_cubit.dart';
import '../features/listen_in/presentation/cubit/review_cubit.dart';
import '../features/listen_in/presentation/pages/listen_setup_page.dart';
import '../features/listen_in/presentation/pages/live_listen_page.dart';
import '../features/listen_in/presentation/pages/review_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/pages/splash_page.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/voice/presentation/bloc/voice_bloc.dart';
import '../features/voice/presentation/pages/voice_page.dart';
import 'di.dart';
import 'routes.dart';

/// Builds each screen with the blocs it needs.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String jurisdictionOf(BuildContext context) =>
        context.read<SettingsCubit>().state.jurisdictionCode;

    switch (settings.name) {
      case Routes.splash:
        return _page(settings, (_) => SplashPage(resolveDestination: sl()));

      case Routes.onboarding:
        return _fade(settings, (_) => OnboardingPage(completeOnboarding: sl()));

      case Routes.login:
        return _fade(
          settings,
          (_) => BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const LoginPage(),
          ),
        );

      case Routes.signup:
        return _page(
          settings,
          (_) => BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const SignupPage(),
          ),
        );

      case Routes.home:
        return _fade(
          settings,
          (_) => BlocProvider(
            create: (_) =>
                HomeCubit(getCurrentUser: sl(), getRecentActivity: sl())
                  ..load(),
            child: const HomePage(),
          ),
        );

      case Routes.history:
        return _page(
          settings,
          (_) => BlocProvider(
            create: (_) => HomeCubit(
              getCurrentUser: sl(),
              getRecentActivity: sl(),
              limit: null,
            )..load(),
            child: const HistoryPage(),
          ),
        );

      case Routes.settings:
        final auth = sl<AuthRepository>();
        return _page(
          settings,
          (_) => BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: SettingsPage(
              user: auth.currentUser,
              canSignOut: auth.requiresSignIn,
            ),
          ),
        );

      case Routes.chat:
        final args = settings.arguments is ChatArgs
            ? settings.arguments! as ChatArgs
            : const ChatArgs();
        return _page(
          settings,
          (context) => BlocProvider(
            create: (context) =>
                ChatBloc(
                  askLegalQuestion: sl(),
                  getConversation: sl(),
                  saveConversation: sl(),
                  deleteConversation: sl(),
                  synthesizer: sl(),
                  jurisdictionCode: () => jurisdictionOf(context),
                )..add(
                  ChatOpened(
                    conversationId: args.conversationId,
                    initialQuestion: args.initialQuestion,
                  ),
                ),
            child: const ChatPage(),
          ),
        );

      case Routes.voice:
        return _page(
          settings,
          (context) => BlocProvider(
            create: (context) => VoiceBloc(
              recognizer: sl(),
              synthesizer: sl(),
              askLegalQuestion: sl(),
              saveConversation: sl(),
              jurisdictionCode: () => jurisdictionOf(context),
            )..add(const VoiceStarted()),
            child: const VoicePage(),
          ),
        );

      case Routes.listenSetup:
        return _fade(
          settings,
          (context) => BlocProvider(
            create: (context) => ListenSetupCubit(
              settings: context.read<SettingsCubit>().state,
              capture: sl(),
              outputRoutes: sl(),
            ),
            child: const ListenSetupPage(),
          ),
        );

      case Routes.listenLive:
        return _page(settings, (_) => const LiveListenPage());

      case Routes.review:
        final args = settings.arguments! as ReviewArgs;
        return _page(
          settings,
          (_) => BlocProvider(
            create: (_) => ReviewCubit(
              sessionId: args.sessionId,
              getSession: sl(),
              loadWaveform: sl(),
              renameSession: sl(),
              deleteSession: sl(),
              shareSession: sl(),
              player: sl(),
              synthesizer: sl(),
            )..load(),
            child: const ReviewPage(),
          ),
        );

      default:
        return _page(settings, (_) => const _NotFound());
    }
  }

  static Route<T> _page<T>(RouteSettings settings, WidgetBuilder builder) =>
      MaterialPageRoute<T>(settings: settings, builder: builder);

  static Route<T> _fade<T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('This page doesn\'t exist.')));
}
