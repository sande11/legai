/// Presentation fakes: make every feature work convincingly on any phone or
/// simulator, with no microphone, speech engine or backend.
///
/// Like test fakes, they implement the same domain interfaces as the real
/// data layer and are swapped in at the composition root. Nothing else in the
/// app knows they exist.
///
/// **On by default.** Build with `--dart-define=LEGAI_FAKES=false` to use the
/// real microphone, speech recognition and sign-in.
///
/// **To remove them for good:**
/// 1. Delete `lib/fakes/` and `assets/fakes/`.
/// 2. In `lib/app/di.dart`, delete the import of this file and the
///    "Presentation fakes" block at the end of `configureDependencies`.
/// 3. In `pubspec.yaml`, delete the two `assets/fakes/` lines.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import '../features/audio/data/flutter_tts_synthesizer.dart';
import '../features/audio/domain/speech_services.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/listen_in/domain/repositories/listen_repositories.dart';
import '../features/listen_in/presentation/bloc/live_listen_bloc.dart';
import 'fake_auth_repository.dart';
import 'fake_content_seeder.dart';
import 'fake_live_capture.dart';
import 'fake_speech.dart';

/// Whether the app runs on presentation fakes.
const bool kPresentationFakes = bool.fromEnvironment(
  'LEGAI_FAKES',
  defaultValue: true,
);

/// Replaces device- and backend-dependent services with fakes, and fills the
/// app with sample history the first time it runs.
///
/// Call after the real registrations, so these override them.
Future<void> installPresentationFakes(
  GetIt sl, {
  AssetBundle? bundle,
  Future<Directory> Function()? tempDir,
  bool audibleVoice = true,
}) async {
  final assets = bundle ?? rootBundle;
  final temp = tempDir ?? getTemporaryDirectory;

  void replace<T extends Object>(T Function() create) {
    if (sl.isRegistered<T>()) sl.unregister<T>();
    sl.registerLazySingleton<T>(create);
  }

  // Sign-in always succeeds; the "account" lives on the phone.
  replace<AuthRepository>(() => FakeAuthRepository(sl()));

  // Talk: a scripted person asks questions; answers are spoken with captions.
  replace<SpeechRecognizer>(FakeSpeechRecognizer.new);
  replace<SpeechSynthesizer>(
    () => FakeSpeechSynthesizer(
      voice: audibleVoice ? FlutterTtsSynthesizer(FlutterTts()) : null,
    ),
  );

  // Pretend earbuds are connected so whispered advice can be shown.
  replace<AudioOutputRoutes>(FakeOutputRoutes.new);

  // Listen In: plays a scripted conversation for the chosen topic.
  replace<LiveCaptureRepository>(
    () => FakeLiveCapture(
      bundle: assets,
      tempDir: temp,
      currentTopic: () => sl<LiveListenBloc>().state.setup?.topic,
    ),
  );

  // Sample chats and recordings for Home and Sessions.
  await FakeContentSeeder(
    prefs: sl(),
    conversations: sl(),
    sessions: sl(),
    analysis: sl(),
    bundle: assets,
    tempDir: temp,
  ).seedOnce();
}
