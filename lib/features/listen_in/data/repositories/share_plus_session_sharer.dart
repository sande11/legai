import 'dart:io';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/storage/json_file_store.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/listen_entities.dart';
import '../../domain/repositories/listen_repositories.dart';

/// Shares the transcript, the flags and the recording through the system
/// share sheet, so the user chooses exactly who gets them.
class SharePlusSessionSharer implements SessionSharer {
  SharePlusSessionSharer(this._store);

  final JsonFileStore _store;

  @override
  Future<void> share(ListenSession session) async {
    final report = await _store.file(
      'sessions/${session.id}/${_slug(session.title)}.txt',
    );
    await report.writeAsString(buildReport(session));
    final files = [XFile(report.path, mimeType: 'text/plain')];
    final audio = session.audioPath;
    if (audio != null && File(audio).existsSync()) {
      files.add(XFile(audio, mimeType: 'audio/wav'));
    }
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: 'LegAI: ${session.title}',
        text: 'Recording and transcript from LegAI: ${session.title}',
      ),
    );
  }

  static String buildReport(ListenSession s) {
    final b = StringBuffer()
      ..writeln(s.title)
      ..writeln(
        '${DateFormat('d MMMM y, HH:mm').format(s.startedAt)} · ${formatLength(s.duration)} · ${s.topic.label}',
      )
      ..writeln();
    if (s.summary != null) {
      b
        ..writeln('Summary')
        ..writeln(s.summary)
        ..writeln();
    }
    if (s.flags.isNotEmpty) {
      b.writeln('Flags');
      for (final f in s.flags) {
        b.writeln('[${formatClock(f.at)}] ${f.kind.label}: ${f.title}');
        if (f.quote != null) b.writeln('  ${f.quote}');
        b.writeln('  ${f.body}${f.citation == null ? '' : ' (${f.citation})'}');
      }
      b.writeln();
    }
    b.writeln('Transcript');
    for (final g in s.segments) {
      final who = g.speaker == null ? '' : '${g.speaker}: ';
      b.writeln('[${formatClock(g.start)}] $who${g.text}');
    }
    b
      ..writeln()
      ..writeln(
        'General legal information from LegAI, not legal representation.',
      );
    return b.toString();
  }

  static String _slug(String s) {
    final slug = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'legai-session' : slug;
  }
}
