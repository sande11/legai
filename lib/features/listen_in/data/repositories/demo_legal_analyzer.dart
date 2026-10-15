import '../../domain/entities/listen_entities.dart';
import '../../domain/repositories/listen_repositories.dart';

/// Rule-based stand-in for an AI analyst, so Listen In flags real moments in
/// a real conversation before a backend exists.
///
/// Each rule looks for a phrase pattern in a finished stretch of speech.
/// Rules can be limited to certain topics, and carry a Malawi citation
/// where one applies.
///
/// NOTE: sample advice for the demo. Have counsel review the wording and
/// citations before release.
class DemoLegalAnalyzer implements LegalAnalysisRepository {
  DemoLegalAnalyzer({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final DateTime Function() _now;

  static final List<AdviceRule> rules = [
    AdviceRule(
      key: 'resignation',
      kind: AdviceKind.caution,
      pattern: r'\bresign\w*\b',
      title: 'You don\'t have to sign today.',
      body:
          'Resigning may weaken an unfair-dismissal claim. Ask for the letter in writing, and for time to get advice.',
    ),
    AdviceRule(
      key: 'sign_now',
      kind: AdviceKind.caution,
      pattern: r'\bsign (this|it|here|now|the|today|before)\b',
      title: 'Don\'t sign on the spot.',
      body:
          'Ask for a copy and time to read it, or to get advice, before you sign anything.',
    ),
    AdviceRule(
      key: 'no_hearing',
      kind: AdviceKind.rights,
      pattern:
          r"(already decided|no need to (hear|go through|discuss)|not interested in your side|don'?t need your side)",
      title: 'You should get a chance to respond.',
      body:
          'Before being dismissed over conduct or performance, you should be given a chance to answer the allegations.',
      malawiCitation: 'Employment Act, s. 57',
      topics: {ConversationTopic.work, ConversationTopic.clientIntake},
    ),
    AdviceRule(
      key: 'dismissal',
      kind: AdviceKind.nextStep,
      pattern: r'\b(dismiss\w*|terminat\w*|fire you|let you go|sack\w*)\b',
      title: 'Ask for the reasons in writing.',
      body:
          'Ask for the allegations and any evidence in writing, and note the date and who is present.',
      topics: {ConversationTopic.work},
    ),
    AdviceRule(
      key: 'withheld_findings',
      kind: AdviceKind.nextStep,
      pattern:
          r"(report|findings|evidence|investigation)\b.*\b(internal|can'?t share|cannot share|confidential|not share)",
      title: 'Ask for the findings in writing.',
      body:
          'Request the findings and any written allegations so you can prepare a response.',
    ),
    AdviceRule(
      key: 'pay_cut',
      kind: AdviceKind.rights,
      pattern:
          r'\b(cut|reduc\w*|lower\w*|decreas\w*)\b.*\b(salary|pay|wage)|\b(salary|pay|wage)\b.*\b(cut|reduc\w*|lower\w*)',
      title: 'A pay cut changes your contract.',
      body:
          'Changing your pay usually needs your agreement. Ask for any change in writing and time to consider it.',
    ),
    AdviceRule(
      key: 'waive_claims',
      kind: AdviceKind.caution,
      pattern:
          r'\b(waive|give up|drop)\b.*\b(right|rights|claim|claims|case)\b',
      title: 'Don\'t give up your rights on the spot.',
      body: 'Ask for time to get advice before agreeing to give up any claim.',
    ),
    AdviceRule(
      key: 'police_statement',
      kind: AdviceKind.rights,
      pattern:
          r'(make a statement|tell us what happened|answer (some|a few) questions|come (with us|to the station)|explain yourself)',
      title: 'You can stay silent.',
      body:
          'You have the right to remain silent, and to be told about it in a language you understand. You can ask for a lawyer first.',
      malawiCitation: 'Constitution of Malawi, s. 42',
    ),
    AdviceRule(
      key: 'arrest',
      kind: AdviceKind.rights,
      pattern:
          r'\b(under arrest|arresting you|you are arrested|detain\w*|lock you up)\b',
      title: 'Ask why you are being held.',
      body:
          'You must be told the reason in a language you understand, and brought before a court within 48 hours.',
      malawiCitation: 'Constitution of Malawi, s. 42',
    ),
    AdviceRule(
      key: 'search',
      kind: AdviceKind.caution,
      pattern: r'\bsearch\w*\b',
      title: 'Ask what the search is for.',
      body:
          'Ask whether they have a warrant and what it covers. Don\'t resist; note what happens and who is there.',
      topics: {ConversationTopic.police},
    ),
    AdviceRule(
      key: 'deposit',
      kind: AdviceKind.nextStep,
      pattern: r'\bdeposit\b',
      title: 'Ask for deductions in writing.',
      body:
          'A landlord can usually only keep a deposit for unpaid rent or damage beyond normal wear and tear. Ask for an itemised list.',
    ),
    AdviceRule(
      key: 'eviction',
      kind: AdviceKind.caution,
      pattern:
          r'\b(evict\w*|get out|move out by|leave the (house|property|flat)|change the locks)\b',
      title: 'Ask for the notice in writing.',
      body:
          'Eviction usually needs proper notice. Ask for it in writing, with the date and the reason.',
      topics: {ConversationTopic.housing, ConversationTopic.family},
    ),
    AdviceRule(
      key: 'late_payment',
      kind: AdviceKind.nextStep,
      pattern:
          r'\b(pay|payment|invoice)\b.*\b(later|next month|delay\w*|\d+ days|end of the (month|quarter))\b',
      title: 'Get payment terms in writing.',
      body:
          'Agree the amount, the due date, and what happens if payment is late, and confirm it by email or contract.',
    ),
    AdviceRule(
      key: 'verbal_deal',
      kind: AdviceKind.caution,
      pattern:
          r"(verbal|handshake|no need (for|to put) (a |it in )?(contract|writing)|we don'?t need a contract)",
      title: 'Put the agreement in writing.',
      body:
          'Verbal agreements can be binding but are hard to prove. Confirm the key terms in writing.',
    ),
    AdviceRule(
      key: 'inheritance',
      kind: AdviceKind.rights,
      pattern:
          r'\b(has passed|passed away|died|the will|a will|estate|inheritance)\b',
      title: 'Ask about the will and the estate.',
      body:
          'Ask whether there is a will and who is handling the estate before you agree to anything about the property.',
      topics: {ConversationTopic.family},
    ),
    AdviceRule(
      key: 'time_limits',
      kind: AdviceKind.nextStep,
      pattern:
          r'\b(\d+|a few|several|two|three|six) (months|years) ago\b|\bdeadline\b|\btime limit\b',
      title: 'Check time limits.',
      body:
          'Note the key dates now. Some claims must be brought within a set time.',
      topics: {
        ConversationTopic.clientIntake,
        ConversationTopic.work,
        ConversationTopic.family,
      },
    ),
  ];

  @override
  Future<List<AdviceFlag>> analyze(
    TranscriptSegment segment,
    AnalysisContext context,
  ) async {
    final text = segment.text;
    final flags = <AdviceFlag>[];
    for (final rule in rules) {
      if (context.alreadyFlagged.contains(rule.key)) continue;
      if (rule.topics != null && !rule.topics!.contains(context.topic)) {
        continue;
      }
      final match = rule.regex.firstMatch(text);
      if (match == null) continue;
      flags.add(
        AdviceFlag(
          id: '${rule.key}-${_now().microsecondsSinceEpoch}',
          key: rule.key,
          kind: rule.kind,
          title: rule.title,
          body: rule.body,
          at: segment.start,
          quote: _quoteAround(text, match.start, match.end),
          citation: context.jurisdictionCode == 'MW'
              ? rule.malawiCitation
              : null,
          segmentId: segment.id,
        ),
      );
      if (flags.length == 2) break; // keep the live view calm
    }
    return flags;
  }

  @override
  Future<String> summarize(ListenSession session) async {
    final flags = session.flags;
    final topic = session.topic.label.toLowerCase();
    if (session.segments.isEmpty) {
      return 'No speech was picked up in this recording.';
    }
    if (flags.isEmpty) {
      return 'LegAI didn\'t flag anything in this $topic conversation. Read the transcript to check the details.';
    }
    final caution = flags.where((f) => f.kind == AdviceKind.caution).length;
    final rights = flags.where((f) => f.kind == AdviceKind.rights).length;
    final parts = <String>[
      if (caution > 0) '$caution ${caution == 1 ? 'caution' : 'cautions'}',
      if (rights > 0) '$rights about your rights',
    ];
    final count = flags.length == 1 ? 'one moment' : '${flags.length} moments';
    final detail = parts.isEmpty ? '' : ', including ${parts.join(' and ')}';
    return 'LegAI flagged $count in this $topic conversation$detail. First: ${flags.first.title}';
  }

  /// Up to ~12 words around the match, as a quote.
  static String _quoteAround(String text, int start, int end) {
    final words = text.split(' ');
    var pos = 0;
    var first = 0;
    var last = words.length - 1;
    for (var i = 0; i < words.length; i++) {
      if (pos <= start) first = i;
      if (pos <= end) last = i;
      pos += words[i].length + 1;
    }
    final from = (first - 4).clamp(0, words.length - 1);
    final to = (last + 5).clamp(0, words.length - 1);
    final quote = words.sublist(from, to + 1).join(' ');
    return '"${from > 0 ? '…' : ''}$quote${to < words.length - 1 ? '…' : ''}"';
  }
}

class AdviceRule {
  AdviceRule({
    required this.key,
    required this.kind,
    required String pattern,
    required this.title,
    required this.body,
    this.malawiCitation,
    this.topics,
  }) : regex = RegExp(pattern, caseSensitive: false);

  final String key;
  final AdviceKind kind;
  final RegExp regex;
  final String title;
  final String body;
  final String? malawiCitation;

  /// Null means the rule applies to every topic.
  final Set<ConversationTopic>? topics;
}
