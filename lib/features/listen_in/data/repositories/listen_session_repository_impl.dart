import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/json_file_store.dart';
import '../../domain/entities/listen_entities.dart';
import '../../domain/repositories/listen_repositories.dart';
import '../datasources/wav_peaks.dart';
import '../models/listen_session_model.dart';

/// Stores each session as `legai/sessions/<id>/session.json` with its
/// recording beside it as `audio.wav`, in the app's private documents
/// folder. Paths are saved relative to that folder because iOS can move the
/// app's container between updates.
class ListenSessionRepositoryImpl implements ListenSessionRepository {
  ListenSessionRepositoryImpl(this._store);

  final JsonFileStore _store;
  static const _folder = 'sessions';

  String _sessionFile(String id) => '$_folder/$id/session.json';
  String _audioFile(String id) => '$_folder/$id/audio.wav';

  @override
  Future<List<ListenSession>> getAll() async {
    final dir = await _store.folder(_folder);
    final sessions = <ListenSession>[];
    for (final entry in dir.listSync().whereType<Directory>()) {
      final id = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final s = await get(id);
      if (s != null) sessions.add(s);
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  @override
  Future<ListenSession?> get(String id) async {
    try {
      final raw = await _store.read(_sessionFile(id));
      if (raw is! Map) return null;
      final session = ListenSessionModel.fromJson(raw.cast<String, Object?>());
      final audio = await _store.file(_audioFile(id));
      return audio.existsSync()
          ? session.copyWith(audioPath: audio.path)
          : session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ListenSession> save(ListenSession session) async {
    try {
      final target = await _store.file(_audioFile(session.id));
      await target.parent.create(recursive: true);
      final source = session.audioPath;
      if (source != null && source != target.path) {
        final file = File(source);
        if (file.existsSync()) {
          try {
            await file.rename(target.path);
          } on FileSystemException {
            // Different volume: copy, then remove the temp file.
            await file.copy(target.path);
            await file.delete();
          }
        }
      }
      final json = ListenSessionModel.toJson(session)
        ..['audioPath'] = _audioFile(session.id);
      await _store.write(_sessionFile(session.id), json);
      return target.existsSync()
          ? session.copyWith(audioPath: target.path)
          : session;
    } catch (_) {
      throw const StorageFailure(
        'Couldn\'t save this recording on your phone.',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    final dir = Directory((await _store.file('$_folder/$id')).path);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<List<double>> waveform(ListenSession session, {int bars = 52}) async {
    final path = session.audioPath;
    if (path == null) return List.filled(bars, 0);
    final file = File(path);
    if (!file.existsSync()) return List.filled(bars, 0);
    final bytes = await file.readAsBytes();
    return compute(wavPeaks, WavPeaksRequest(bytes, bars));
  }
}
