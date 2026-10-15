import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../domain/entities/listen_entities.dart';

extension AdviceKindStyle on AdviceKind {
  IconData get icon => switch (this) {
    AdviceKind.rights => LucideIcons.shield,
    AdviceKind.caution => LucideIcons.triangleAlert,
    AdviceKind.nextStep => LucideIcons.arrowRight,
  };

  Color foreground(LegaiColors c) => switch (this) {
    AdviceKind.rights => c.goldText,
    AdviceKind.caution => c.caution,
    AdviceKind.nextStep => c.next,
  };

  Color background(LegaiColors c) => switch (this) {
    AdviceKind.rights => c.goldSoft,
    AdviceKind.caution => c.cautionSoft,
    AdviceKind.nextStep => c.nextSoft,
  };
}

/// "Your rights" / "Caution" / "Next step" pill. Colour, icon and label all
/// carry the meaning, so it never relies on colour alone.
class AdviceKindChip extends StatelessWidget {
  const AdviceKindChip({super.key, required this.kind});
  final AdviceKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = kind.foreground(c);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: ShapeDecoration(
        color: kind.background(c),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(kind.label, style: context.text.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// The live advice card. New advice slides up into place.
class AdviceCard extends StatelessWidget {
  const AdviceCard({
    super.key,
    required this.flag,
    required this.earlierCount,
    required this.onHearAgain,
    required this.onAsk,
    required this.onEarlier,
  });

  final AdviceFlag flag;
  final int earlierCount;
  final VoidCallback onHearAgain;
  final VoidCallback onAsk;
  final VoidCallback onEarlier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      label: '${flag.kind.label}. ${flag.title} ${flag.body}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.goldLine),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AdviceKindChip(kind: flag.kind),
                const SizedBox(width: 8),
                Text(
                  'at ${formatClock(flag.at)}',
                  style: context.text.labelSmall?.copyWith(
                    color: c.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: flag.whispered ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          LucideIcons.headphones,
                          size: 13,
                          color: c.goldText,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Whispered',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall?.copyWith(
                              color: c.goldText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(flag.title, style: context.text.titleLarge),
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Text(
                flag.citation == null
                    ? flag.body
                    : '${flag.body} ${flag.citation}.',
                style: context.text.bodySmall?.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SoftPillButton(
                  label: 'Hear again',
                  icon: LucideIcons.volume2,
                  onPressed: onHearAgain,
                ),
                SoftPillButton(
                  label: 'Ask about this',
                  icon: LucideIcons.messageSquare,
                  onPressed: onAsk,
                ),
                if (earlierCount > 0)
                  TextButton(
                    onPressed: onEarlier,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: Text('$earlierCount earlier'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A flagged moment in the review list; tap to expand.
class FlagTile extends StatelessWidget {
  const FlagTile({
    super.key,
    required this.flag,
    required this.expanded,
    required this.onToggle,
    required this.onPlay,
    required this.onHear,
    required this.onAsk,
  });

  final AdviceFlag flag;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onPlay;
  final VoidCallback onHear;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: expanded ? c.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: expanded ? c.goldLine : c.line),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              expanded: expanded,
              button: true,
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AdviceKindChip(kind: flag.kind),
                          const SizedBox(width: 8),
                          Text(
                            formatClock(flag.at),
                            style: context.text.labelSmall?.copyWith(
                              color: c.muted,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: 18,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(flag.title, style: context.text.titleMedium),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (flag.quote != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: c.quoteBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                flag.quote!,
                                style: TextStyle(
                                  fontFamily: LegaiFonts.serif,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                  height: 1.4,
                                  color: c.text,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            flag.citation == null
                                ? flag.body
                                : '${flag.body} ${flag.citation}.',
                            style: context.text.bodySmall?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SoftPillButton(
                                label: 'Play moment',
                                icon: LucideIcons.play,
                                onPressed: onPlay,
                              ),
                              SoftPillButton(
                                label: 'Hear advice',
                                icon: LucideIcons.volume2,
                                onPressed: onHear,
                              ),
                              SoftPillButton(
                                label: 'Ask LegAI',
                                icon: LucideIcons.messageSquare,
                                onPressed: onAsk,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of transcript: time, then the words. Flagged words get the gold
/// underline used everywhere for "LegAI has something to say about this".
class TranscriptLine extends StatelessWidget {
  const TranscriptLine({
    super.key,
    required this.segment,
    this.flagged = false,
    this.live = false,
  });

  final TranscriptSegment segment;
  final bool flagged;

  /// Still being recognised: shown muted.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Text(
      segment.text,
      style: context.text.bodyLarge?.copyWith(color: live ? c.muted : c.text),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: flagged
                    ? c.gold
                    : (segment.speaker == 'You' ? c.text : c.next),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            if (segment.speaker != null) ...[
              Text(
                segment.speaker!,
                style: context.text.labelSmall?.copyWith(color: c.muted),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              live ? 'now' : formatClock(segment.start),
              style: context.text.labelSmall?.copyWith(
                color: c.muted,
                fontWeight: segment.speaker == null
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (flagged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: c.goldSoft,
              border: Border(bottom: BorderSide(color: c.gold, width: 2)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: text,
          )
        else
          text,
      ],
    );
  }
}
