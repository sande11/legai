import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/listen_in/data/repositories/demo_legal_analyzer.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/usecases/listen_in_usecases.dart';
import 'package:legai/features/listen_in/presentation/bloc/live_listen_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeCapture capture;
  late FakeSynthesizer tts;
  late FakeOutputRoutes routes;
  late InMemorySessions sessions;
  late LiveListenBloc bloc;

  const setup = ListenSetup(
    topic: ConversationTopic.work,
    announce: true,
    whisper: true,
    jurisdictionCode: 'MW',
  );

  setUp(() {
    capture = FakeCapture();
    tts = FakeSynthesizer();
    routes = FakeOutputRoutes();
    sessions = InMemorySessions();
    final analyzer = DemoLegalAnalyzer();
    bloc = LiveListenBloc(
      capture: capture,
      analyzeSegment: AnalyzeSegment(analyzer),
      finishSession: FinishListenSession(analyzer, sessions),
      synthesizer: tts,
      outputRoutes: routes,
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test(
    'announces out loud when no earbuds are connected, then records',
    () async {
      bloc.add(const LiveStarted(setup));
      await settle();
      expect(tts.spoken.first, 'This conversation is being recorded.');
      expect(capture.started, isTrue);
      expect(bloc.state.status, LiveStatus.recording);
    },
  );

  test(
    'with earbuds, asks the user to announce instead and whispers advice',
    () async {
      routes.private = true;
      bloc.add(const LiveStarted(setup));
      await settle();
      expect(tts.spoken, isEmpty);
      expect(bloc.state.notice, contains('Tell everyone'));

      capture.say('Given all that, we think it\'s best you resign today.');
      await settle();
      expect(bloc.state.flags.single.kind, AdviceKind.caution);
      expect(bloc.state.shownFlag?.key, 'resignation');
      expect(tts.spoken.single, startsWith('You don\'t have to sign today.'));
      expect(bloc.state.flags.single.whispered, isTrue);
    },
  );

  test('never whispers through the loudspeaker', () async {
    bloc.add(const LiveStarted(setup));
    await settle();
    tts.spoken.clear();
    capture.say('Please resign.');
    await settle();
    expect(bloc.state.flags, hasLength(1));
    expect(tts.spoken, isEmpty);
  });

  test(
    'transcript builds segments and the toggle opens and closes it',
    () async {
      bloc.add(const LiveStarted(setup));
      await settle();
      capture
        ..say('We went through the stock count.', isFinal: true)
        ..say('We went through the stock count. I raised that', isFinal: false);
      await settle();
      expect(bloc.state.segments, hasLength(2));
      expect(bloc.state.latestSegment!.isFinal, isFalse);

      expect(bloc.state.transcriptExpanded, isFalse);
      bloc.add(const LiveTranscriptToggled());
      await settle();
      expect(bloc.state.transcriptExpanded, isTrue);
    },
  );

  test('stopping saves the session with transcript, flags and marks', () async {
    bloc.add(const LiveStarted(setup));
    await settle();
    capture.say('If you sign this letter now we will keep it quiet.');
    await settle();
    bloc.add(const LiveMarkPressed());
    bloc.add(const LiveStopRequested());
    await settle();

    expect(capture.stopped, isTrue);
    expect(bloc.state.status, LiveStatus.saved);
    final saved = sessions.saved[bloc.state.savedSessionId]!;
    expect(saved.title, 'Work conversation');
    expect(saved.segments, isNotEmpty);
    expect(saved.flags, isNotEmpty);
    expect(saved.marks, hasLength(1));
    expect(saved.summary, contains('flagged'));
    expect(saved.audioPath, '/tmp/legai-test.wav');
  });

  test('pause and resume follow the controls and the system', () async {
    bloc.add(const LiveStarted(setup));
    await settle();
    bloc.add(const LivePauseToggled());
    await settle();
    expect(bloc.state.isPaused, isTrue);
    expect(capture.paused, isTrue);
    bloc.add(const LivePauseToggled());
    await settle();
    expect(bloc.state.status, LiveStatus.recording);

    capture.interruptionsController.add(true);
    await settle();
    expect(bloc.state.isPaused, isTrue);
    expect(bloc.state.notice, contains('paused'));
  });
}
