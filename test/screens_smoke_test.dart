import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legai/features/auth/presentation/pages/login_page.dart';
import 'package:legai/features/chat/domain/usecases/chat_usecases.dart';
import 'package:legai/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:legai/features/chat/presentation/pages/chat_page.dart';
import 'package:legai/features/home/presentation/pages/history_page.dart';
import 'package:legai/features/home/presentation/pages/home_page.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';
import 'package:legai/features/listen_in/domain/usecases/listen_in_usecases.dart';
import 'package:legai/features/listen_in/presentation/bloc/live_listen_bloc.dart';
import 'package:legai/features/listen_in/presentation/cubit/listen_setup_cubit.dart';
import 'package:legai/features/listen_in/presentation/cubit/review_cubit.dart';
import 'package:legai/features/listen_in/presentation/pages/listen_setup_page.dart';
import 'package:legai/features/listen_in/presentation/pages/live_listen_page.dart';
import 'package:legai/features/listen_in/presentation/pages/review_page.dart';
import 'package:legai/features/onboarding/domain/usecases/resolve_start_destination.dart';
import 'package:legai/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:legai/features/settings/presentation/pages/settings_page.dart';
import 'package:legai/features/auth/data/repositories/guest_auth_repository.dart';
import 'package:legai/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:legai/features/voice/presentation/bloc/voice_bloc.dart';
import 'package:legai/features/voice/presentation/pages/voice_page.dart';
import 'package:legai/features/audio/domain/speech_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'helpers/fonts.dart';
import 'helpers/harness.dart';

/// Renders the screen and fails on any layout or build error (overflows
/// included). Run with `--dart-define=LEGAI_SHOTS=true` to also write PNGs to `build/screens/`.
Future<void> shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  if (const bool.fromEnvironment('LEGAI_SHOTS')) {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/screens/$name.png'),
    );
  }
}

class _Player implements RecordingPlayer {
  @override
  Future<Duration?> load(String path) async =>
      const Duration(minutes: 18, seconds: 12);
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<bool> get playing => const Stream.empty();
  @override
  Future<void> dispose() async {}
}

/// A large and a small phone.
const _sizes = [(390.0, 844.0), (375.0, 667.0)];

void main() {
  setUpAll(loadAppFonts);

  for (final size in _sizes) {
    for (final dark in [true, false]) {
      final t =
          '${dark ? 'dark' : 'light'}_${size.$1.toInt()}x${size.$2.toInt()}';

      testWidgets('home $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        await rig.seedHistory();
        final home = rig.homeCubit();
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(value: home..load(), child: const HomePage()),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await shot(tester, '01_home_$t');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('chat $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        final bloc =
            ChatBloc(
              askLegalQuestion: rig.ask(),
              getConversation: GetConversation(rig.conversations),
              saveConversation: SaveConversation(rig.conversations),
              deleteConversation: DeleteConversation(rig.conversations),
              synthesizer: rig.tts,
              jurisdictionCode: () => 'MW',
            )..add(
              const ChatOpened(
                initialQuestion:
                    'The police called and asked me to come to the station "to answer a few questions". Do I have to say anything?',
              ),
            );
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(value: bloc, child: const ChatPage()),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 800));
        await shot(tester, '02_chat_$t');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('voice $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        final rec = FakeRecognizer();
        final bloc = VoiceBloc(
          recognizer: rec,
          synthesizer: rig.tts,
          askLegalQuestion: rig.ask(),
          saveConversation: SaveConversation(rig.conversations),
          jurisdictionCode: () => 'MW',
        )..add(const VoiceStarted());
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(value: bloc, child: const VoicePage()),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        rec.session!.add(
          const RecognitionUpdate(
            'My employer wants me to sign a new contract with a lower salary. Can they make me',
            isFinal: false,
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await shot(tester, '03_voice_$t');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('setup $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        final cubit = ListenSetupCubit(
          settings: rig.settings.state,
          capture: rig.capture,
          outputRoutes: FakeOutputRoutes(),
        );
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(value: cubit, child: const ListenSetupPage()),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await shot(tester, '04_setup_$t');
        await tester.pumpWidget(const SizedBox());
      });

      for (final expanded in [false, true]) {
        testWidgets('live $t $expanded', (tester) async {
          usePhone(tester, width: size.$1, height: size.$2);
          final rig = await TestRig.create();
          await tester.pumpWidget(rig.wrap(const LiveListenPage(), dark: dark));
          rig.live.add(
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
          rig.capture
            ..say(
              'We\'ve gone through last month\'s stock count, and the numbers don\'t add up.',
              speaker: 'Manager',
            )
            ..say(
              'We\'ve gone through last month\'s stock count, and the numbers don\'t add up. I raised that in my report on the 3rd.',
              speaker: 'Manager',
            )
            ..say(
              'We\'ve gone through last month\'s stock count, and the numbers don\'t add up. I raised that in my report on the 3rd. Given all that, we think it\'s best you resign today. If you sign this letter now, we\'ll keep it quiet.',
              speaker: 'Manager',
            )
            ..say(
              'We\'ve gone through last month\'s stock count, and the numbers don\'t add up. I raised that in my report on the 3rd. Given all that, we think it\'s best you resign today. If you sign this letter now, we\'ll keep it quiet. HR needs it signed before you leave',
              isFinal: false,
              speaker: 'Manager',
            );
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 130));
          }
          if (expanded) {
            rig.live.add(const LiveTranscriptToggled());
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 500));
          }
          await shot(tester, '05_live_${expanded ? 'open' : 'min'}_$t');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(rig.live.close);
        });
      }

      testWidgets('review $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        await rig.seedHistory();
        final cubit = ReviewCubit(
          sessionId: 'hr',
          getSession: GetListenSession(rig.sessions),
          loadWaveform: LoadSessionWaveform(rig.sessions),
          renameSession: RenameListenSession(rig.sessions),
          deleteSession: DeleteListenSession(rig.sessions),
          shareSession: ShareListenSession(_NoShare()),
          player: _Player(),
          synthesizer: rig.tts,
        );
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(value: cubit..load(), child: const ReviewPage()),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await shot(tester, '06_review_$t');
        await tester.tap(find.text('You don\'t have to sign today.'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
        await shot(tester, '07_review_open_$t');
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(cubit.close);
      });

      testWidgets('settings $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(
              value: rig.authBloc(),
              child: const SettingsPage(user: null, canSignOut: false),
            ),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await shot(tester, '08_settings_$t');
      });

      testWidgets('history $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        await rig.seedHistory();
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(
              value: rig.homeCubit(limit: null)..load(),
              child: const HistoryPage(),
            ),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await shot(tester, '09_history_$t');
      });

      testWidgets('onboarding+login $t', (tester) async {
        usePhone(tester, width: size.$1, height: size.$2);
        final rig = await TestRig.create();
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          rig.wrap(
            OnboardingPage(
              completeOnboarding: CompleteOnboarding(
                OnboardingRepositoryImpl(prefs),
                GuestAuthRepository(),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await shot(tester, '10_onboarding_$t');
        await tester.pumpWidget(
          rig.wrap(
            BlocProvider.value(value: rig.authBloc(), child: const LoginPage()),
            dark: dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await shot(tester, '11_login_$t');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

class _NoShare implements SessionSharer {
  @override
  Future<void> share(ListenSession session) async {}
}
