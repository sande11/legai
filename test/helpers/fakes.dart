import 'dart:async';

import 'package:legai/features/audio/domain/speech_services.dart';
import 'package:legai/features/chat/domain/entities/chat_entities.dart';
import 'package:legai/features/chat/domain/repositories/chat_repositories.dart';
import 'package:legai/features/listen_in/domain/entities/listen_entities.dart';
import 'package:legai/features/listen_in/domain/repositories/listen_repositories.dart';

class FakeSynthesizer implements SpeechSynthesizer {
  final spoken = <String>[];
  final _progress = StreamController<SpeechProgress>.broadcast();

  @override
  Future<void> configure({required String locale}) async {}

  @override
  Future<void> prepareForRecording() async {}

  @override
  Stream<SpeechProgress> get progress => _progress.stream;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

class FakeOutputRoutes implements AudioOutputRoutes {
  FakeOutputRoutes({this.private = false});
  bool private;

  @override
  Future<bool> hasPrivateOutput() async => private;
}

class FakeCapture implements LiveCaptureRepository {
  final updatesController = StreamController<CaptureUpdate>.broadcast();
  final interruptionsController = StreamController<bool>.broadcast();
  bool started = false;
  bool stopped = false;
  bool paused = false;
  String? audioPath = '/tmp/legai-test.wav';

  void say(String fullText, {bool isFinal = true}) =>
      updatesController.add(CaptureUpdate(fullText, isFinal: isFinal));

  @override
  Stream<CaptureUpdate> get updates => updatesController.stream;

  @override
  Stream<bool> get interruptions => interruptionsController.stream;

  @override
  Future<void> ensurePermission() async {}

  @override
  Future<void> start({required String localeId}) async => started = true;

  @override
  Future<double> level() async => 0.4;

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  Future<String?> stop() async {
    stopped = true;
    return audioPath;
  }

  @override
  Future<void> cancel() async {}
}

class InMemorySessions implements ListenSessionRepository {
  final saved = <String, ListenSession>{};

  @override
  Future<void> delete(String id) async => saved.remove(id);

  @override
  Future<ListenSession?> get(String id) async => saved[id];

  @override
  Future<List<ListenSession>> getAll() async => saved.values.toList();

  @override
  Future<ListenSession> save(ListenSession session) async =>
      saved[session.id] = session;

  @override
  Future<List<double>> waveform(ListenSession session, {int bars = 52}) async =>
      List.filled(bars, 0.5);
}

class InMemoryConversations implements ConversationRepository {
  final items = <String, Conversation>{};

  @override
  Future<void> delete(String id) async => items.remove(id);

  @override
  Future<Conversation?> get(String id) async => items[id];

  @override
  Future<List<Conversation>> getAll() async => items.values.toList();

  @override
  Future<void> save(Conversation conversation) async =>
      items[conversation.id] = conversation;
}
