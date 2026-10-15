import '../../../../core/usecase/usecase.dart';
import '../entities/listen_entities.dart';
import '../repositories/listen_repositories.dart';

class AnalyzeSegmentParams {
  const AnalyzeSegmentParams(this.segment, this.context);
  final TranscriptSegment segment;
  final AnalysisContext context;
}

/// Checks a finished stretch of speech for moments that need advice.
class AnalyzeSegment
    implements UseCase<List<AdviceFlag>, AnalyzeSegmentParams> {
  const AnalyzeSegment(this._analysis);
  final LegalAnalysisRepository _analysis;

  @override
  Future<List<AdviceFlag>> call(AnalyzeSegmentParams p) async {
    if (!p.segment.isFinal || p.segment.text.trim().length < 3) return const [];
    final flags = await _analysis.analyze(p.segment, p.context);
    return flags
        .where((f) => !p.context.alreadyFlagged.contains(f.key))
        .toList();
  }
}

/// Summarises and saves a finished conversation.
class FinishListenSession implements UseCase<ListenSession, ListenSession> {
  const FinishListenSession(this._analysis, this._sessions);
  final LegalAnalysisRepository _analysis;
  final ListenSessionRepository _sessions;

  @override
  Future<ListenSession> call(ListenSession session) async {
    final summary = await _analysis.summarize(session);
    return _sessions.save(session.copyWith(summary: summary));
  }
}

class GetListenSessions implements UseCase<List<ListenSession>, NoParams> {
  const GetListenSessions(this._sessions);
  final ListenSessionRepository _sessions;

  @override
  Future<List<ListenSession>> call(NoParams params) => _sessions.getAll();
}

class GetListenSession implements UseCase<ListenSession?, String> {
  const GetListenSession(this._sessions);
  final ListenSessionRepository _sessions;

  @override
  Future<ListenSession?> call(String id) => _sessions.get(id);
}

class RenameListenSession
    implements UseCase<ListenSession, (ListenSession, String)> {
  const RenameListenSession(this._sessions);
  final ListenSessionRepository _sessions;

  @override
  Future<ListenSession> call((ListenSession, String) p) {
    final title = p.$2.trim();
    if (title.isEmpty) return Future.value(p.$1);
    return _sessions.save(p.$1.copyWith(title: title));
  }
}

class DeleteListenSession implements UseCase<void, String> {
  const DeleteListenSession(this._sessions);
  final ListenSessionRepository _sessions;

  @override
  Future<void> call(String id) => _sessions.delete(id);
}

class LoadSessionWaveform implements UseCase<List<double>, ListenSession> {
  const LoadSessionWaveform(this._sessions);
  final ListenSessionRepository _sessions;

  @override
  Future<List<double>> call(ListenSession s) => _sessions.waveform(s);
}

class ShareListenSession implements UseCase<void, ListenSession> {
  const ShareListenSession(this._sharer);
  final SessionSharer _sharer;

  @override
  Future<void> call(ListenSession s) => _sharer.share(s);
}
