import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/chat/data/datasources/demo_legal_knowledge_base.dart';
import '../features/chat/domain/entities/chat_entities.dart';
import '../features/chat/domain/repositories/chat_repositories.dart';
import '../features/listen_in/domain/entities/listen_entities.dart';
import '../features/listen_in/domain/repositories/listen_repositories.dart';
import 'fake_scripts.dart';

/// Fills Home and Sessions with sample history the first time the app runs
/// on fakes: two Listen In recordings (with audio) and two chats.
class FakeContentSeeder {
  FakeContentSeeder({
    required this._prefs,
    required this._conversations,
    required this._sessions,
    required this._analysis,
    required this._bundle,
    required this._tempDir,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final ConversationRepository _conversations;
  final ListenSessionRepository _sessions;
  final LegalAnalysisRepository _analysis;
  final AssetBundle _bundle;
  final Future<Directory> Function() _tempDir;
  final DateTime Function() _now;

  static const _seededKey = 'fakes.seeded.v1';

  Future<void> seedOnce() async {
    if (_prefs.getBool(_seededKey) ?? false) return;
    try {
      final now = _now();
      await _recording(
        id: 'demo-hr-meeting',
        title: 'HR meeting, stock count',
        topic: ConversationTopic.work,
        startedAt: now.subtract(const Duration(hours: 2)),
      );
      await _recording(
        id: 'demo-supplier-call',
        title: 'Supplier call, payment terms',
        topic: ConversationTopic.businessDeal,
        startedAt: now.subtract(const Duration(days: 3, hours: 4)),
      );
      await _chat(
        id: 'demo-police-chat',
        question: 'Do I have to answer police questions?',
        at: now.subtract(const Duration(days: 1, hours: 5)),
        channel: ConversationChannel.text,
      );
      await _chat(
        id: 'demo-deposit-talk',
        question: 'Can my landlord keep my deposit?',
        at: now.subtract(const Duration(days: 2, hours: 1)),
        channel: ConversationChannel.voice,
      );
      await _prefs.setBool(_seededKey, true);
    } catch (_) {
      // Sample history is a nice-to-have; the app works without it.
    }
  }

  Future<void> _recording({
    required String id,
    required String title,
    required ConversationTopic topic,
    required DateTime startedAt,
  }) async {
    final script = await FakeScript.forTopic(_bundle, topic);
    final segments = [
      for (var i = 0; i < script.lines.length; i++)
        TranscriptSegment(
          id: 'seg-$i',
          text: script.lines[i].text,
          start: script.lines[i].start,
          isFinal: true,
          speaker: script.lines[i].speaker,
        ),
    ];

    final flags = <AdviceFlag>[];
    for (final segment in segments) {
      final found = await _analysis.analyze(
        segment,
        AnalysisContext(
          topic: topic,
          jurisdictionCode: 'MW',
          alreadyFlagged: flags.map((f) => f.key).toSet(),
        ),
      );
      flags.addAll(found.map((f) => f.copyWith(whispered: true)));
    }

    final audio = await _bundle.load(script.audioAsset);
    final dir = await _tempDir();
    final file = File('${dir.path}${Platform.pathSeparator}$id.wav');
    await file.writeAsBytes(
      audio.buffer.asUint8List(audio.offsetInBytes, audio.lengthInBytes),
      flush: true,
    );

    final session = ListenSession(
      id: id,
      title: title,
      topic: topic,
      startedAt: startedAt,
      duration: script.length,
      jurisdictionCode: 'MW',
      audioPath: file.path,
      segments: segments,
      flags: flags,
    );
    await _sessions.save(
      session.copyWith(summary: await _analysis.summarize(session)),
    );
  }

  Future<void> _chat({
    required String id,
    required String question,
    required DateTime at,
    required ConversationChannel channel,
  }) async {
    final answer = const DemoLegalKnowledgeBase().answer(
      question,
      jurisdictionCode: 'MW',
    );
    await _conversations.save(
      Conversation(
        id: id,
        title: question,
        updatedAt: at,
        jurisdictionCode: 'MW',
        channel: channel,
        messages: [
          ChatMessage(
            id: '$id-q',
            role: MessageRole.user,
            text: question,
            createdAt: at,
          ),
          ChatMessage(
            id: '$id-a',
            role: MessageRole.assistant,
            text: answer.summary,
            createdAt: at.add(const Duration(seconds: 2)),
            answer: answer,
          ),
        ],
      ),
    );
  }
}
