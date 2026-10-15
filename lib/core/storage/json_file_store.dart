import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Reads and writes JSON documents in the app's private documents folder.
///
/// Everything LegAI saves (chats, Listen In sessions, recordings) lives here,
/// on the phone only.
class JsonFileStore {
  JsonFileStore({Future<Directory> Function()? rootProvider})
    : _rootProvider = rootProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _rootProvider;
  Directory? _root;

  Future<Directory> root() async {
    final cached = _root;
    if (cached != null) return cached;
    final base = await _rootProvider();
    final dir = Directory('${base.path}${Platform.pathSeparator}legai');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _root = dir;
  }

  Future<Directory> folder(String name) async {
    final r = await root();
    final dir = Directory('${r.path}${Platform.pathSeparator}$name');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> file(String relativePath) async {
    final r = await root();
    return File('${r.path}${Platform.pathSeparator}$relativePath');
  }

  Future<Object?> read(String relativePath) async {
    final f = await file(relativePath);
    if (!f.existsSync()) return null;
    final raw = await f.readAsString();
    if (raw.trim().isEmpty) return null;
    return jsonDecode(raw);
  }

  /// Writes atomically: to a temp file first, then renames over the target.
  Future<void> write(String relativePath, Object? json) async {
    final f = await file(relativePath);
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename(f.path);
  }

  Future<void> delete(String relativePath) async {
    final f = await file(relativePath);
    if (f.existsSync()) await f.delete();
  }
}
