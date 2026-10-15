import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:stt_record/stt_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/storage/json_file_store.dart';
import '../features/audio/data/audio_session_output_routes.dart';
import '../features/audio/data/flutter_tts_synthesizer.dart';
import '../features/audio/data/just_audio_recording_player.dart';
import '../features/audio/data/speech_to_text_recognizer.dart';
import '../features/audio/domain/speech_services.dart';
import '../features/auth/data/repositories/guest_auth_repository.dart';
import '../features/auth/data/repositories/supabase_auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/chat/data/repositories/conversation_repository_impl.dart';
import '../features/chat/data/repositories/demo_legal_assistant_repository.dart';
import '../features/chat/domain/repositories/chat_repositories.dart';
import '../features/chat/domain/usecases/chat_usecases.dart';
import '../features/home/domain/usecases/get_recent_activity.dart';
import '../features/listen_in/data/repositories/demo_legal_analyzer.dart';
import '../features/listen_in/data/repositories/listen_session_repository_impl.dart';
import '../features/listen_in/data/repositories/share_plus_session_sharer.dart';
import '../features/listen_in/data/repositories/stt_record_capture_repository.dart';
import '../features/listen_in/domain/repositories/listen_repositories.dart';
import '../features/listen_in/domain/usecases/listen_in_usecases.dart';
import '../features/listen_in/presentation/bloc/live_listen_bloc.dart';
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/resolve_start_destination.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/domain/usecases/settings_usecases.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';

/// The service locator. Only the composition root (this file, the router and
/// main.dart) reads from it; everything else gets dependencies through
/// constructors.
final sl = GetIt.instance;

Future<void> configureDependencies({required bool backendConfigured}) async {
  final prefs = await SharedPreferences.getInstance();

  // External & core -------------------------------------------------------------
  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<JsonFileStore>(JsonFileStore.new);

  // Audio -------------------------------------------------------------------------
  sl
    ..registerLazySingleton<SpeechRecognizer>(
      () => SpeechToTextRecognizer(SpeechToText()),
    )
    ..registerLazySingleton<SpeechSynthesizer>(
      () => FlutterTtsSynthesizer(FlutterTts()),
    )
    ..registerLazySingleton<AudioOutputRoutes>(AudioSessionOutputRoutes.new)
    ..registerFactory<RecordingPlayer>(JustAudioRecordingPlayer.new);

  // Settings ----------------------------------------------------------------------
  sl
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => LoadSettings(sl()))
    ..registerLazySingleton(() => SaveSettings(sl()))
    ..registerLazySingleton(
      () => SettingsCubit(loadSettings: sl(), saveSettings: sl()),
    );

  // Auth & onboarding -------------------------------------------------------------
  sl
    ..registerLazySingleton<AuthRepository>(
      () => backendConfigured
          ? SupabaseAuthRepository(Supabase.instance.client)
          : GuestAuthRepository(),
    )
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerFactory(() => AuthBloc(signIn: sl(), signUp: sl(), signOut: sl()))
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => ResolveStartDestination(sl(), sl()))
    ..registerLazySingleton(() => CompleteOnboarding(sl(), sl()));

  // Chat --------------------------------------------------------------------------
  sl
    // Swap DemoLegalAssistantRepository for a backend-powered implementation
    // here; nothing else needs to change.
    ..registerLazySingleton<LegalAssistantRepository>(
      DemoLegalAssistantRepository.new,
    )
    ..registerLazySingleton<ConversationRepository>(
      () => ConversationRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => AskLegalQuestion(sl()))
    ..registerLazySingleton(() => GetConversation(sl()))
    ..registerLazySingleton(() => GetConversations(sl()))
    ..registerLazySingleton(() => SaveConversation(sl()))
    ..registerLazySingleton(() => DeleteConversation(sl()));

  // Listen In ---------------------------------------------------------------------
  sl
    ..registerLazySingleton<LiveCaptureRepository>(
      () => SttRecordCaptureRepository(SttRecord()),
    )
    // Swap DemoLegalAnalyzer for a backend-powered analyst here.
    ..registerLazySingleton<LegalAnalysisRepository>(DemoLegalAnalyzer.new)
    ..registerLazySingleton<ListenSessionRepository>(
      () => ListenSessionRepositoryImpl(sl()),
    )
    ..registerLazySingleton<SessionSharer>(() => SharePlusSessionSharer(sl()))
    ..registerLazySingleton(() => AnalyzeSegment(sl()))
    ..registerLazySingleton(() => FinishListenSession(sl(), sl()))
    ..registerLazySingleton(() => GetListenSessions(sl()))
    ..registerLazySingleton(() => GetListenSession(sl()))
    ..registerLazySingleton(() => RenameListenSession(sl()))
    ..registerLazySingleton(() => DeleteListenSession(sl()))
    ..registerLazySingleton(() => LoadSessionWaveform(sl()))
    ..registerLazySingleton(() => ShareListenSession(sl()))
    ..registerLazySingleton(
      () => LiveListenBloc(
        capture: sl(),
        analyzeSegment: sl(),
        finishSession: sl(),
        synthesizer: sl(),
        outputRoutes: sl(),
      ),
    );

  // Home ----------------------------------------------------------------------------
  sl.registerLazySingleton(() => GetRecentActivity(sl(), sl()));
}
