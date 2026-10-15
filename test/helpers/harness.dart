import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legai/core/theme/legai_theme.dart';
import 'package:legai/features/audio/domain/speech_services.dart';
import 'package:legai/features/auth/data/repositories/guest_auth_repository.dart';
import 'package:legai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:legai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:legai/features/chat/data/repositories/demo_legal_assistant_repository.dart';
import 'package:legai/features/chat/domain/entities/chat_entities.dart';
import 'package:legai/features/chat/domain/usecases/chat_usecases.dart';
import 'package:legai/features/home/domain/usecases/get_recent_activity.dart';
import 'package:legai/features/home/presentation/cubit/home_cubit.dart';
import 'package:legai/features/listen_in/data/repositories/demo_legal_analyzer.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';
import 'package:legai/features/listen_in/domain/usecases/listen_in_usecases.dart';
import 'package:legai/features/listen_in/presentation/bloc/live_listen_bloc.dart';
import 'package:legai/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:legai/features/settings/domain/usecases/settings_usecases.dart';
import 'package:legai/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class FakeRecognizer implements SpeechRecognizer {
  final levels = StreamController<double>.broadcast();
  StreamController<RecognitionUpdate>? session;

  @override
  Future<bool> initialize() async => true;

  @override
  Stream<RecognitionUpdate> listen({required String localeId}) {
    session = StreamController<RecognitionUpdate>();
    return session!.stream;
  }

  @override
  Stream<double> get soundLevels => levels.stream;

  @override
  Future<void> stop() async => session?.close();

  @override
  Future<void> cancel() async => session?.close();
}

/// Everything a screen needs from the app root, with fakes behind it.
class TestRig {
  TestRig._(
    this.settings,
    this.live,
    this.conversations,
    this.sessions,
    this.capture,
    this.tts,
  );

  final SettingsCubit settings;
  final LiveListenBloc live;
  final InMemoryConversations conversations;
  final InMemorySessions sessions;
  final FakeCapture capture;
  final FakeSynthesizer tts;

  static Future<TestRig> create() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepositoryImpl(prefs);
    final settings = SettingsCubit(
      loadSettings: LoadSettings(repo),
      saveSettings: SaveSettings(repo),
    );
    await settings.load();
    final capture = FakeCapture();
    final tts = FakeSynthesizer();
    final sessions = InMemorySessions();
    final analyzer = DemoLegalAnalyzer();
    final live = LiveListenBloc(
      capture: capture,
      analyzeSegment: AnalyzeSegment(analyzer),
      finishSession: FinishListenSession(analyzer, sessions),
      synthesizer: tts,
      outputRoutes: FakeOutputRoutes(),
    );
    return TestRig._(
      settings,
      live,
      InMemoryConversations(),
      sessions,
      capture,
      tts,
    );
  }

  Future<void> seedHistory() async {
    final now = DateTime.now();
    final analyzer = DemoLegalAnalyzer();
    const seg = TranscriptSegment(
      id: 's1',
      text:
          'Given all that, we think it\'s best you resign today. If you sign this letter now, we\'ll keep it quiet.',
      start: Duration(minutes: 12, seconds: 36),
      isFinal: true,
    );
    const seg0 = TranscriptSegment(
      id: 's0',
      text:
          'We have already decided, so there\'s no need to go through your side.',
      start: Duration(minutes: 4, seconds: 12),
      isFinal: true,
    );
    const ctx = AnalysisContext(
      topic: ConversationTopic.work,
      jurisdictionCode: 'MW',
    );
    final flags = [
      ...await analyzer.analyze(seg0, ctx),
      ...await analyzer.analyze(seg, ctx),
    ];
    await sessions.save(
      ListenSession(
        id: 'hr',
        title: 'HR meeting, stock count',
        topic: ConversationTopic.work,
        startedAt: now.subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 18, seconds: 12),
        jurisdictionCode: 'MW',
        audioPath: '/tmp/none.wav',
        segments: [seg0, seg],
        flags: flags,
        summary:
            'Your manager asked you to resign over last month\'s stock count. You weren\'t shown the findings or asked to respond first.',
      ),
    );
    await conversations.save(
      Conversation(
        id: 'c1',
        title: 'Do I have to answer police questions?',
        messages: const [],
        updatedAt: now.subtract(const Duration(days: 1)),
        jurisdictionCode: 'MW',
      ),
    );
  }

  HomeCubit homeCubit({int? limit = 3}) => HomeCubit(
    getCurrentUser: GetCurrentUser(GuestAuthRepository()),
    getRecentActivity: GetRecentActivity(conversations, sessions),
    limit: limit,
  );

  AuthBloc authBloc() {
    final repo = GuestAuthRepository();
    return AuthBloc(
      signIn: SignIn(repo),
      signUp: SignUp(repo),
      signOut: SignOut(repo),
    );
  }

  AskLegalQuestion ask() => AskLegalQuestion(
    DemoLegalAssistantRepository(thinkingTime: Duration.zero),
  );

  Widget wrap(Widget child, {bool dark = true}) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: settings),
      BlocProvider.value(value: live),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? LegaiTheme.dark : LegaiTheme.light,
      onGenerateRoute: (s) => MaterialPageRoute(
        settings: s,
        builder: (_) => Scaffold(body: Text('route ${s.name}')),
      ),
      home: child,
    ),
  );
}

void usePhone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view
    ..physicalSize = Size(width * 3, height * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
