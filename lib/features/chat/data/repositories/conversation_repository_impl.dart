import '../../../../core/error/failures.dart';
import '../../../../core/storage/json_file_store.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/chat_repositories.dart';
import '../models/conversation_model.dart';

/// Keeps every conversation in one JSON file on the device.
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._store);

  final JsonFileStore _store;
  static const _file = 'conversations.json';
  List<Conversation>? _cache;

  Future<List<Conversation>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final raw = await _store.read(_file);
      final list = (raw as List?) ?? const [];
      return _cache = list
          .cast<Map>()
          .map((m) => ConversationModel.fromJson(m.cast<String, Object?>()))
          .toList();
    } catch (_) {
      return _cache = [];
    }
  }

  Future<void> _persist(List<Conversation> all) async {
    _cache = all;
    try {
      await _store.write(_file, all.map(ConversationModel.toJson).toList());
    } catch (_) {
      throw const StorageFailure(
        'Couldn\'t save this conversation on your phone.',
      );
    }
  }

  @override
  Future<List<Conversation>> getAll() async {
    final all = [...await _load()];
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  @override
  Future<Conversation?> get(String id) async {
    for (final c in await _load()) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<void> save(Conversation conversation) async {
    final all = [...await _load()]..removeWhere((c) => c.id == conversation.id);
    await _persist([conversation, ...all]);
  }

  @override
  Future<void> delete(String id) async {
    final all = [...await _load()]..removeWhere((c) => c.id == id);
    await _persist(all);
  }
}
