import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:legai/core/error/failures.dart';
import 'package:legai/fakes/fake_auth_repository.dart';
import 'package:legai/fakes/fake_content_seeder.dart';
import 'package:legai/fakes/fake_live_capture.dart';
import 'package:legai/fakes/fake_scripts.dart';
import 'package:legai/fakes/fake_speech.dart';
import 'package:legai/fakes/fakes.dart';
import 'package:legai/features/audio/domain/speech_services.dart';
import 'package:legai/features/auth/data/repositories/guest_auth_repository.dart';
import 'package:legai/features/auth/domain/repositories/auth_repository.dart';
import 'package:legai/features/chat/domain/entities/chat_entities.dart';
import 'package:legai/features/chat/domain/repositories/chat_repositories.dart';
import 'package:legai/features/listen_in/data/repositories/demo_legal_analyzer.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';
import 'package:legai/features/listen_in/domain/usecases/listen_in_usecases.dart';
import 'package:legai/features/listen_in/presentation/bloc/live_listen_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart' as test_fakes;

/// Waits (in real time) until [done] is true.
Future<void> until(bool Function() done, {int seconds = 10}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Timed out');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('legai-fakes-');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  group('scripts', () {
    for (final topic in ConversationTopic.values) {
      test(
        '${topic.name}: timed lines that match the audio and draw advice',
        () async {
          final script = await FakeScript.forTopic(rootBundle, topic);
          final pcm = await FakePcm.load(rootBundle, script.audioAsset);
          final audio = Duration(
            milliseconds: pcm.samples.length * 1000 ~/ pcm.sampleRate,
          );

          expect(script.lines, isNotEmpty);
          expect(script.lines.map((l) => l.speaker), contains('You'));
          var previous = Duration.zero;
          for (final line in script.lines) {
            expect(line.start, greaterThanOrEqualTo(previous));
            expect(line.end, greaterThan(line.start));
            previous = line.end;
          }
          expect(audio, greaterThanOrEqualTo(script.lines.last.end));
          expect((audio - script.length).inMilliseconds.abs(), lessThan(200));

          final analyzer = DemoLegalAnalyzer();
          final keys = <String>{};
          for (var i = 0; i < script.lines.length; i++) {
            final flags = await analyzer.analyze(
              TranscriptSegment(
                id: '$i',
                text: script.lines[i].text,
                start: script.lines[i].start,
                isFinal: true,
              ),
              AnalysisContext(
                topic: topic,
                jurisdictionCode: 'MW',
                alreadyFlagged: keys,
              ),
            );
            keys.addAll(flags.map((f) => f.key));
          }
          expect(keys, isNotEmpty, reason: 'No advice for ${topic.name}');
        },
      );
    }
  });

  group('FakeLiveCapture', () {
    FakeLiveCapture capture({double speed = 40}) => FakeLiveCapture(
      bundle: rootBundle,
      currentTopic: () => ConversationTopic.police,
      tempDir: () async => temp,
      speed: speed,
      tick: const Duration(milliseconds: 10),
    );

    test('hears the topic script line by line, then saves its audio', () async {
      final script = await FakeScript.forTopic(
        rootBundle,
        ConversationTopic.police,
      );
      final fake = capture();
      final updates = <CaptureUpdate>[];
      final sub = fake.updates.listen(updates.add);
      final levels = <double>[];

      await fake.start(localeId: 'en_GB');
      await until(() {
        unawaited(fake.level().then(levels.add));
        return updates.where((u) => u.isFinal).length == script.lines.length;
      });
      await sub.cancel();

      final finals = updates.where((u) => u.isFinal).toList();
      expect(finals.map((u) => u.speaker), script.lines.map((l) => l.speaker));
      expect(finals.last.fullText, script.lines.map((l) => l.text).join(' '));
      expect(updates.where((u) => !u.isFinal), isNotEmpty);
      expect(levels.reduce((a, b) => a > b ? a : b), greaterThan(0.2));

      final path = await fake.stop();
      expect(path, isNotNull);
      final saved = FakePcm.decode(File(path!).readAsBytesSync());
      final length = Duration(
        milliseconds: saved.samples.length * 1000 ~/ saved.sampleRate,
      );
      expect(length, greaterThanOrEqualTo(script.lines.last.end));
    });

    test('pausing stops the conversation until it resumes', () async {
      final fake = capture(speed: 4);
      final updates = <CaptureUpdate>[];
      final sub = fake.updates.listen(updates.add);
      await fake.start(localeId: 'en_GB');
      await until(() => updates.isNotEmpty);

      await fake.pause();
      final count = updates.length;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(updates.length, count);

      await fake.resume();
      await until(() => updates.length > count);
      await fake.cancel();
      await sub.cancel();
    });
  });

  test(
    'Listen In end to end: advice appears and the recording is saved',
    () async {
      final script = await FakeScript.forTopic(
        rootBundle,
        ConversationTopic.family,
      );
      final sessions = test_fakes.InMemorySessions();
      final analyzer = DemoLegalAnalyzer();
      late LiveListenBloc bloc;
      bloc = LiveListenBloc(
        capture: FakeLiveCapture(
          bundle: rootBundle,
          currentTopic: () => bloc.state.setup?.topic,
          tempDir: () async => temp,
          speed: 40,
          tick: const Duration(milliseconds: 10),
        ),
        analyzeSegment: AnalyzeSegment(analyzer),
        finishSession: FinishListenSession(analyzer, sessions),
        synthesizer: FakeSpeechSynthesizer(
          wordDuration: const Duration(milliseconds: 1),
        ),
        outputRoutes: FakeOutputRoutes(),
      );

      bloc.add(
        const LiveStarted(
          ListenSetup(
            topic: ConversationTopic.family,
            announce: true,
            whisper: true,
            jurisdictionCode: 'MW',
          ),
        ),
      );
      await until(
        () =>
            bloc.state.segments.where((g) => g.isFinal).length ==
            script.lines.length,
      );
      expect(bloc.state.flags, isNotEmpty);
      // Advice is whispered through the (fake) earbuds, one at a time.
      await until(() => bloc.state.flags.every((f) => f.whispered));
      expect(
        bloc.state.segments.map((g) => g.speaker),
        script.lines.map((l) => l.speaker),
      );

      bloc.add(const LiveStopRequested());
      await until(() => bloc.state.status == LiveStatus.saved);
      final saved = sessions.saved[bloc.state.savedSessionId]!;
      expect(saved.segments.first.speaker, 'Relative');
      expect(saved.flags, isNotEmpty);
      expect(File(saved.audioPath!).existsSync(), isTrue);
      await bloc.close();
    },
  );

  group('FakeSpeechRecognizer', () {
    test('hears a question word by word, then the next one', () async {
      final fake = FakeSpeechRecognizer(
        questions: const ['Can they do that?', 'Do I have to?'],
        wordInterval: const Duration(milliseconds: 5),
        leadIn: const Duration(milliseconds: 5),
      );
      expect(await fake.initialize(), isTrue);

      final first = await fake.listen(localeId: 'en_GB').toList();
      expect(first.first, const RecognitionUpdate('Can', isFinal: false));
      expect(
        first.last,
        const RecognitionUpdate('Can they do that?', isFinal: true),
      );

      final second = await fake.listen(localeId: 'en_GB').toList();
      expect(second.last.text, 'Do I have to?');
    });

    test('stopping early finishes the sentence', () async {
      final fake = FakeSpeechRecognizer(
        questions: const ['Can my landlord keep my deposit?'],
        leadIn: const Duration(hours: 1),
      );
      final updates = fake.listen(localeId: 'en_GB').toList();
      await fake.stop();
      expect(await updates, const [
        RecognitionUpdate('Can my landlord keep my deposit?', isFinal: true),
      ]);
    });
  });

  group('FakeSpeechSynthesizer', () {
    test('reports each word, then completes', () async {
      final fake = FakeSpeechSynthesizer(
        wordDuration: const Duration(milliseconds: 2),
      );
      final ends = <int>[];
      final sub = fake.progress.listen((p) => ends.add(p.end));
      await fake.speak('You can refuse.');
      await sub.cancel();
      expect(ends, [3, 7, 15]);
      expect(fake.spoken, ['You can refuse.']);
    });

    test('stop ends speech at once', () async {
      final fake = FakeSpeechSynthesizer(
        wordDuration: const Duration(hours: 1),
      );
      final speaking = fake.speak('A long answer');
      await fake.stop();
      await expectLater(speaking, completes);
    });
  });

  group('FakeAuthRepository', () {
    test('signs in with any email and a 6+ character password', () async {
      final prefs = await SharedPreferences.getInstance();
      final auth = FakeAuthRepository(prefs, delay: Duration.zero);
      expect(auth.requiresSignIn, isTrue);
      expect(auth.currentUser, isNull);

      expect(
        () => auth.signIn(email: 'a@b.mw', password: '123'),
        throwsA(isA<AuthFailure>()),
      );
      final user = await auth.signIn(email: ' a@b.mw ', password: '123456');
      expect(user.email, 'a@b.mw');

      await auth.signOut();
      expect(auth.currentUser, isNull);

      await auth.signUp(name: 'Chikondi', email: 'c@d.mw', password: 'x');
      expect(auth.currentUser?.name, 'Chikondi');
    });
  });

  group('FakeContentSeeder', () {
    test('adds two recordings and two chats, once', () async {
      final prefs = await SharedPreferences.getInstance();
      final sessions = test_fakes.InMemorySessions();
      final chats = test_fakes.InMemoryConversations();
      FakeContentSeeder seeder() => FakeContentSeeder(
        prefs: prefs,
        conversations: chats,
        sessions: sessions,
        analysis: DemoLegalAnalyzer(),
        bundle: rootBundle,
        tempDir: () async => temp,
      );

      await seeder().seedOnce();

      expect(sessions.saved.keys, ['demo-hr-meeting', 'demo-supplier-call']);
      for (final s in sessions.saved.values) {
        expect(s.flags, isNotEmpty);
        expect(s.summary, isNotNull);
        expect(s.segments.every((g) => g.speaker != null), isTrue);
        expect(File(s.audioPath!).existsSync(), isTrue);
      }
      expect(chats.items.keys, ['demo-police-chat', 'demo-deposit-talk']);
      expect(
        chats.items['demo-deposit-talk']!.channel,
        ConversationChannel.voice,
      );

      sessions.saved.clear();
      chats.items.clear();
      await seeder().seedOnce();
      expect(sessions.saved, isEmpty);
      expect(chats.items, isEmpty);
    });
  });

  test(
    'installPresentationFakes swaps the device and backend services',
    () async {
      final sl = GetIt.asNewInstance();
      sl
        ..registerSingleton<SharedPreferences>(
          await SharedPreferences.getInstance(),
        )
        ..registerLazySingleton<AuthRepository>(GuestAuthRepository.new)
        ..registerLazySingleton<SpeechSynthesizer>(
          test_fakes.FakeSynthesizer.new,
        )
        ..registerLazySingleton<AudioOutputRoutes>(
          test_fakes.FakeOutputRoutes.new,
        )
        ..registerLazySingleton<LiveCaptureRepository>(
          test_fakes.FakeCapture.new,
        )
        ..registerLazySingleton<ConversationRepository>(
          test_fakes.InMemoryConversations.new,
        )
        ..registerLazySingleton<ListenSessionRepository>(
          test_fakes.InMemorySessions.new,
        )
        ..registerLazySingleton<LegalAnalysisRepository>(DemoLegalAnalyzer.new);

      await installPresentationFakes(
        sl,
        bundle: rootBundle,
        tempDir: () async => temp,
        audibleVoice: false,
      );

      expect(sl<AuthRepository>(), isA<FakeAuthRepository>());
      expect(sl<SpeechRecognizer>(), isA<FakeSpeechRecognizer>());
      expect(sl<SpeechSynthesizer>(), isA<FakeSpeechSynthesizer>());
      expect(sl<AudioOutputRoutes>(), isA<FakeOutputRoutes>());
      expect(await sl<AudioOutputRoutes>().hasPrivateOutput(), isTrue);
      expect(sl<LiveCaptureRepository>(), isA<FakeLiveCapture>());
      expect(await sl<ListenSessionRepository>().getAll(), hasLength(2));
      expect(await sl<ConversationRepository>().getAll(), hasLength(2));
    },
  );
}
