import 'package:equatable/equatable.dart';

import '../entities/listen_entities.dart';

/// The recognizer's running transcript of the whole session so far.
class CaptureUpdate extends Equatable {
  const CaptureUpdate(this.fullText, {required this.isFinal, this.speaker});

  /// Everything heard since the session started.
  final String fullText;

  /// True when the recognizer has committed the latest words.
  final bool isFinal;

  /// Who is speaking, when the source can tell (on-device recognizers
  /// can't; a diarizing cloud service can).
  final String? speaker;

  @override
  List<Object?> get props => [fullText, isFinal, speaker];
}

/// Records audio to a file and transcribes it at the same time, from one
/// microphone stream.
abstract interface class LiveCaptureRepository {
  /// Throws [PermissionFailure] if the microphone (or speech) is refused.
  Future<void> ensurePermission();

  /// Throws [SpeechUnavailableFailure] if the phone has no recognizer.
  Future<void> start({required String localeId});

  Stream<CaptureUpdate> get updates;

  /// Emits true when the system pauses capture (a phone call, for example)
  /// and false when it resumes.
  Stream<bool> get interruptions;

  /// Microphone level 0–1.
  Future<double> level();

  Future<void> pause();
  Future<void> resume();

  /// Finishes the recording and returns the audio file's path.
  Future<String?> stop();

  Future<void> cancel();
}

class AnalysisContext extends Equatable {
  const AnalysisContext({
    required this.topic,
    required this.jurisdictionCode,
    this.alreadyFlagged = const {},
  });

  final ConversationTopic topic;
  final String jurisdictionCode;

  /// Keys of advice already given in this conversation.
  final Set<String> alreadyFlagged;

  @override
  List<Object?> get props => [topic, jurisdictionCode, alreadyFlagged];
}

/// Spots moments that need legal advice.
abstract interface class LegalAnalysisRepository {
  Future<List<AdviceFlag>> analyze(
    TranscriptSegment segment,
    AnalysisContext context,
  );

  /// A two-sentence summary for the review screen.
  Future<String> summarize(ListenSession session);
}

/// Listen In sessions and their recordings, kept on the phone.
abstract interface class ListenSessionRepository {
  Future<List<ListenSession>> getAll();
  Future<ListenSession?> get(String id);

  /// Saves the session. A recording at [audioPath] (in a temporary folder) is
  /// moved next to it so the system can't clear it.
  Future<ListenSession> save(ListenSession session);

  Future<void> delete(String id);

  /// Peak levels (0–1) for drawing the waveform, [bars] long.
  Future<List<double>> waveform(ListenSession session, {int bars = 52});
}

/// Hands a session to another app (mail, messaging) to share with a lawyer.
abstract interface class SessionSharer {
  Future<void> share(ListenSession session);
}
