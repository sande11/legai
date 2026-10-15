import '../../../../core/usecase/usecase.dart';
import '../../../chat/domain/entities/chat_entities.dart';
import '../../../chat/domain/repositories/chat_repositories.dart';
import '../../../listen_in/domain/entities/listen_entities.dart';
import '../../../listen_in/domain/repositories/listen_repositories.dart';
import '../entities/recent_activity.dart';

/// Merges chats, voice conversations and Listen In sessions, newest first.
class GetRecentActivity implements UseCase<List<RecentActivity>, int?> {
  const GetRecentActivity(this._conversations, this._sessions);

  final ConversationRepository _conversations;
  final ListenSessionRepository _sessions;

  /// Pass a limit, or null for everything.
  @override
  Future<List<RecentActivity>> call(int? limit) async {
    final results = await Future.wait([
      _conversations.getAll(),
      _sessions.getAll(),
    ]);
    final convos = results[0] as List<Conversation>;
    final sessions = results[1] as List<ListenSession>;
    final items = <RecentActivity>[
      for (final c in convos)
        RecentActivity(
          id: c.id,
          kind: c.channel == ConversationChannel.voice
              ? ActivityKind.talk
              : ActivityKind.ask,
          title: c.title,
          date: c.updatedAt,
        ),
      for (final s in sessions)
        RecentActivity(
          id: s.id,
          kind: ActivityKind.listenIn,
          title: s.title,
          date: s.startedAt,
          length: s.duration,
          flagCount: s.flags.length,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return limit == null ? items : items.take(limit).toList();
  }
}
