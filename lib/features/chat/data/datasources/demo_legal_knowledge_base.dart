import '../../domain/entities/chat_entities.dart';

/// Built-in answers so the whole app works before a real AI backend exists.
///
/// Each topic has a Malawi answer (with the law it relies on) and a general
/// answer for other countries. Replace this with a backend-powered
/// `LegalAssistantRepository` when one is ready.
///
/// NOTE: these are sample answers for the demo. Have counsel review the
/// wording and citations before relying on them.
class DemoLegalKnowledgeBase {
  const DemoLegalKnowledgeBase();

  static const _constitutionS42 = LegalSource(
    title: 'Constitution of Malawi · s. 42',
    detail: 'Arrest, detention and fair trial',
  );
  static const _employmentS57 = LegalSource(
    title: 'Employment Act · s. 57',
    detail: 'Termination of employment',
  );

  static final List<DemoTopic> topics = [
    DemoTopic(
      id: 'bring_someone',
      patterns: [
        r'\bbring\b.*\b(someone|somebody|friend|lawyer|relative|family)',
        r'\bsomeone with me\b',
      ],
      malawi: const LegalAnswer(
        summary:
            'You can ask for a lawyer to be with you before you answer questions.',
        points: [
          'You have the right to consult a lawyer of your choice, and to be told about that right.',
          'If you are held, you can ask to contact a family member or someone you trust.',
          'Whether a friend can sit in on the interview is up to the police, but you can ask.',
        ],
        sources: [_constitutionS42],
        followUps: [
          'What if they don\'t charge me?',
          'Do I have to answer police questions?',
        ],
      ),
      general: const LegalAnswer(
        summary:
            'In most countries you can ask for a lawyer before you answer police questions.',
        points: [
          'Ask clearly: "I would like to speak to a lawyer before I answer."',
          'Whether a friend can sit in is usually up to the police, but you can ask.',
        ],
        followUps: ['What if they don\'t charge me?'],
      ),
    ),
    DemoTopic(
      id: 'not_charged',
      patterns: [
        r'\b(charge|charged|charging)\b',
        r'\b48 hours\b',
        r'\bhow long\b.*\b(hold|keep|detain)',
      ],
      malawi: const LegalAnswer(
        summary:
            'If you are arrested, you must be brought before a court within 48 hours, or released.',
        points: [
          'At court you must be charged or told why you are still being held.',
          'You must be told the reason for your arrest in a language you understand.',
          'You can apply for bail.',
        ],
        sources: [_constitutionS42],
        followUps: ['Can I bring someone with me?', 'How does bail work?'],
      ),
      general: const LegalAnswer(
        summary:
            'Most countries limit how long police can hold you without charge. The limit depends on where you are.',
        points: [
          'Ask why you are being held and how long they can keep you.',
          'Ask to speak to a lawyer.',
        ],
        followUps: ['Can I bring someone with me?'],
      ),
    ),
    DemoTopic(
      id: 'police_questioning',
      patterns: [
        r'\bpolice\b',
        r'\b(station|interview|statement|questioning|questions?)\b',
        r'\b(silent|silence)\b',
      ],
      malawi: const LegalAnswer(
        summary:
            'Short answer: you can go, but you don\'t have to answer questions that could be used against you.',
        points: [
          'You have the right to remain silent, and to be told about it in a language you understand.',
          'You can ask to speak with a lawyer before answering.',
          'If you\'re arrested, you must be told why and brought before a court within 48 hours.',
        ],
        sources: [_constitutionS42],
        followUps: [
          'Can I bring someone with me?',
          'What if they don\'t charge me?',
        ],
      ),
      general: const LegalAnswer(
        summary:
            'In most countries you can stay silent and ask for a lawyer before answering police questions.',
        points: [
          'Stay calm and polite. You can say: "I\'d like to speak to a lawyer first."',
          'Ask whether you are under arrest or free to leave.',
        ],
        followUps: [
          'Can I bring someone with me?',
          'What if they don\'t charge me?',
        ],
      ),
    ),
    DemoTopic(
      id: 'resignation',
      patterns: [r'\bresign', r'\bsign\b.*\bletter\b'],
      malawi: const LegalAnswer(
        summary: 'You don\'t have to sign a resignation letter on the spot.',
        points: [
          'Resigning may weaken an unfair-dismissal claim.',
          'Ask for the letter, and any allegations against you, in writing.',
          'Ask for time to get advice before you decide.',
        ],
        sources: [_employmentS57],
        followUps: [
          'What counts as unfair dismissal?',
          'Can they fire me without a hearing?',
        ],
      ),
      general: const LegalAnswer(
        summary: 'You don\'t have to sign a resignation letter on the spot.',
        points: [
          'Resigning can weaken a later claim that you were dismissed unfairly.',
          'Ask for everything in writing and time to get advice.',
        ],
        followUps: ['What counts as unfair dismissal?'],
      ),
    ),
    DemoTopic(
      id: 'dismissal',
      patterns: [
        r'\b(fired|fire me|dismiss\w*|terminat\w*|sacked|let go|disciplinary|hearing)\b',
        r'\bunfair\b',
      ],
      malawi: const LegalAnswer(
        summary:
            'Before you are dismissed over your conduct or performance, you should get a chance to answer the allegations.',
        points: [
          'Your employer needs a valid reason to end your employment.',
          'Ask for the allegations and any evidence in writing.',
          'Keep notes of meetings, with dates and who was there.',
        ],
        sources: [_employmentS57],
        followUps: [
          'Should I sign a resignation letter?',
          'Can they cut my salary?',
        ],
      ),
      general: const LegalAnswer(
        summary:
            'In many countries an employer needs a fair reason and a fair process before dismissing you.',
        points: [
          'Ask for the reasons and any evidence in writing.',
          'Ask for a chance to respond before a decision is made.',
          'Keep notes of meetings, with dates and who was there.',
        ],
        followUps: ['Should I sign a resignation letter?'],
      ),
    ),
    DemoTopic(
      id: 'pay_cut',
      patterns: [
        r'\b(salary|pay|wage|wages)\b.*\b(cut|reduc\w*|lower\w*|decreas\w*)',
        r'\b(cut|reduc\w*|lower\w*)\b.*\b(salary|pay|wage)',
      ],
      malawi: const LegalAnswer(
        summary:
            'Usually not on their own. Your pay is part of your contract, so changing it generally needs your agreement.',
        points: [
          'Ask for any proposed change in writing.',
          'You don\'t have to agree in the meeting. Ask for time to consider it.',
        ],
        followUps: ['Can they fire me if I say no?'],
      ),
      general: const LegalAnswer(
        summary:
            'Usually not on their own. Pay is part of your contract, so changing it generally needs your agreement.',
        points: ['Ask for any change in writing, and for time to consider it.'],
        followUps: ['Can they fire me if I say no?'],
      ),
    ),
    DemoTopic(
      id: 'tenancy',
      patterns: [r'\b(landlord|tenant|tenancy|deposit|rent|lease|evict\w*)\b'],
      malawi: const LegalAnswer(
        summary:
            'A landlord can usually only keep a deposit for unpaid rent or damage beyond normal wear and tear.',
        points: [
          'Ask for an itemised list of deductions, in writing.',
          'Photos from when you moved in and out are strong evidence.',
          'If you\'re asked to leave, ask for the notice in writing, with the date and reason.',
        ],
        followUps: ['Is a verbal tenancy agreement binding?'],
      ),
      general: const LegalAnswer(
        summary:
            'A landlord can usually only keep a deposit for unpaid rent or damage beyond normal wear and tear.',
        points: [
          'Ask for an itemised list of deductions, in writing.',
          'Photos from move-in and move-out are strong evidence.',
        ],
        followUps: ['Is a verbal tenancy agreement binding?'],
      ),
    ),
    DemoTopic(
      id: 'contracts',
      patterns: [
        r'\b(verbal|oral|handshake|contract|agreement|invoice|supplier|payment terms)\b',
      ],
      malawi: const LegalAnswer(
        summary:
            'Verbal agreements can be binding, but they are hard to prove.',
        points: [
          'Confirm the key terms in writing, even by email or message.',
          'Agree the price, the due date, and what happens if payment is late.',
        ],
        followUps: ['What can I do if a client doesn\'t pay?'],
      ),
      general: const LegalAnswer(
        summary:
            'Verbal agreements can be binding, but they are hard to prove.',
        points: ['Confirm the key terms in writing, even by email or message.'],
        followUps: ['What can I do if a client doesn\'t pay?'],
      ),
    ),
    DemoTopic(
      id: 'recording',
      patterns: [r'\brecord\w*\b'],
      malawi: const LegalAnswer(
        summary:
            'Rules on recording a conversation differ from place to place. The safest habit is to tell everyone first.',
        points: [
          'Listen In can announce the recording for you when it starts.',
          'Recordings stay on your phone unless you choose to share them.',
        ],
      ),
      general: const LegalAnswer(
        summary:
            'Rules on recording a conversation differ from place to place. The safest habit is to tell everyone first.',
        points: [
          'Listen In can announce the recording for you when it starts.',
        ],
      ),
    ),
  ];

  static const fallback = LegalAnswer(
    summary:
        'I can help with questions about work, the police, housing, contracts and more.',
    points: [
      'Tell me what happened, who is involved, and what you would like to know.',
      'For your own case, a lawyer can give advice that covers every detail.',
    ],
    followUps: [
      'Do I have to answer police questions?',
      'Can my employer cut my salary?',
      'Can my landlord keep my deposit?',
    ],
  );

  /// Picks the best-matching topic, or the fallback.
  LegalAnswer answer(String question, {required String jurisdictionCode}) {
    final q = question.toLowerCase();
    DemoTopic? best;
    var bestScore = 0;
    for (final topic in topics) {
      final score = topic.score(q);
      if (score > bestScore) {
        best = topic;
        bestScore = score;
      }
    }
    final chosen = best == null
        ? fallback
        : (jurisdictionCode == 'MW' ? best.malawi : best.general);
    return LegalAnswer(
      summary: chosen.summary,
      points: chosen.points,
      sources: chosen.sources,
      followUps: chosen.followUps,
      isDemo: true,
    );
  }
}

class DemoTopic {
  DemoTopic({
    required this.id,
    required List<String> patterns,
    required this.malawi,
    required this.general,
  }) : _patterns = patterns
           .map((p) => RegExp(p, caseSensitive: false))
           .toList();

  final String id;
  final List<RegExp> _patterns;
  final LegalAnswer malawi;
  final LegalAnswer general;

  /// Earlier patterns are more specific, so they weigh more.
  int score(String question) {
    var s = 0;
    for (var i = 0; i < _patterns.length; i++) {
      if (_patterns[i].hasMatch(question)) s += _patterns.length - i + 1;
    }
    return s;
  }
}
