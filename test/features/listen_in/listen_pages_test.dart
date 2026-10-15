import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legai/core/theme/legai_theme.dart';
import 'package:legai/features/audio/domain/speech_services.dart';
import 'package:legai/features/listen_in/data/repositories/demo_legal_analyzer.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';
import 'package:legai/features/listen_in/domain/usecases/listen_in_usecases.dart';
import 'package:legai/features/listen_in/presentation/bloc/live_listen_bloc.dart';
import 'package:legai/features/listen_in/presentation/cubit/review_cubit.dart';
import 'package:legai/features/listen_in/presentation/pages/live_listen_page.dart';
import 'package:legai/features/listen_in/presentation/pages/review_page.dart';

import '../../helpers/fakes.dart';
import '../../helpers/fonts.dart';

class _FakePlayer implements RecordingPlayer {
  final _pos = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  @override
  Future<Duration?> load(String path) async => const Duration(minutes: 18);
  @override
  Future<void> play() async => _playing.add(true);
  @override
  Future<void> pause() async => _playing.add(false);
  @override
  Future<void> seek(Duration position) async => _pos.add(position);
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Future<void> dispose() async {}
}

class _NoopSharer implements SessionSharer {
  @override
  Future<void> share(ListenSession session) async {}
}

Widget _app(Widget child, {ThemeData? theme}) =>
    MaterialApp(theme: theme ?? LegaiTheme.dark, home: child);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('live page: transcript starts minimised and can be shown', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final capture = FakeCapture();
    final analyzer = DemoLegalAnalyzer();
    final bloc = LiveListenBloc(
      capture: capture,
      analyzeSegment: AnalyzeSegment(analyzer),
      finishSession: FinishListenSession(analyzer, InMemorySessions()),
      synthesizer: FakeSynthesizer(),
      outputRoutes: FakeOutputRoutes(),
    );

    await tester.pumpWidget(
      _app(BlocProvider.value(value: bloc, child: const LiveListenPage())),
    );
    bloc.add(
      const LiveStarted(
        ListenSetup(
          topic: ConversationTopic.work,
          announce: false,
          whisper: true,
          jurisdictionCode: 'MW',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    capture
      ..say('We went through the stock count.')
      ..say(
        'We went through the stock count. Given all that, it is best you resign today.',
      );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));

    // Minimised: only the latest line, plus the advice card.
    expect(find.text('Show'), findsOneWidget);
    expect(find.text('We went through the stock count.'), findsNothing);
    expect(find.text('You don\'t have to sign today.'), findsOneWidget);

    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('We went through the stock count.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(bloc.close);
  });

  testWidgets('review page: flags start closed and open on tap', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final sessions = InMemorySessions();
    final analyzer = DemoLegalAnalyzer();
    final segment = const TranscriptSegment(
      id: 's1',
      text: 'We think it is best you resign today.',
      start: Duration(minutes: 12, seconds: 36),
      isFinal: true,
    );
    final flags = await analyzer.analyze(
      segment,
      const AnalysisContext(
        topic: ConversationTopic.work,
        jurisdictionCode: 'MW',
      ),
    );
    await sessions.save(
      ListenSession(
        id: 'abc',
        title: 'HR meeting, stock count',
        topic: ConversationTopic.work,
        startedAt: DateTime.now(),
        duration: const Duration(minutes: 18, seconds: 12),
        jurisdictionCode: 'MW',
        audioPath: '/tmp/a.wav',
        segments: [segment],
        flags: flags,
        summary: 'Your manager asked you to resign.',
      ),
    );

    final cubit = ReviewCubit(
      sessionId: 'abc',
      getSession: GetListenSession(sessions),
      loadWaveform: LoadSessionWaveform(sessions),
      renameSession: RenameListenSession(sessions),
      deleteSession: DeleteListenSession(sessions),
      shareSession: ShareListenSession(_NoopSharer()),
      player: _FakePlayer(),
      synthesizer: FakeSynthesizer(),
    );

    await tester.pumpWidget(
      _app(
        BlocProvider.value(value: cubit..load(), child: const ReviewPage()),
        theme: LegaiTheme.light,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('HR meeting, stock count'), findsOneWidget);
    expect(find.text('Flags · 1'), findsOneWidget);
    expect(
      find.textContaining('resign today'),
      findsNothing,
      reason: 'quote hidden while closed',
    );

    await tester.tap(find.text('You don\'t have to sign today.'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('resign today'), findsOneWidget);

    await tester.tap(find.text('Transcript'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('We think it is best you resign today.'), findsOneWidget);

    // Unmount first, then close outside the fake clock (stream teardown is real async).
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(cubit.close);
  });
}
