import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/waveform_bars.dart';
import '../../domain/entities/listen_entities.dart';
import '../cubit/review_cubit.dart';
import '../widgets/advice_widgets.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  Future<void> _more(BuildContext context, ListenSession session) async {
    final cubit = context.read<ReviewCubit>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Rename'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: context.colors.red),
              title: Text(
                'Delete recording',
                style: TextStyle(color: context.colors.red),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'rename') {
      final title = await _askTitle(context, session.title);
      if (title != null) await cubit.rename(title);
    } else if (choice == 'delete') {
      final ok = await confirm(
        context,
        title: 'Delete this recording?',
        message:
            'The audio, transcript and flags will be removed from this phone.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (ok) await cubit.delete();
    }
  }

  Future<String?> _askTitle(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<ReviewCubit, ReviewState>(
      listenWhen: (a, b) =>
          (b.message != null && a.message != b.message) ||
          (b.deleted && !a.deleted),
      listener: (context, state) {
        if (state.deleted) {
          Navigator.of(context).maybePop();
          return;
        }
        showLegaiSnack(context, state.message!, icon: LucideIcons.info);
        context.read<ReviewCubit>().messageShown();
      },
      builder: (context, state) {
        final cubit = context.read<ReviewCubit>();
        final session = state.session;
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'This recording couldn\'t be found.',
                style: context.text.bodyMedium,
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    Row(
                      children: [
                        CircleIconButton(
                          icon: LucideIcons.chevronLeft,
                          label: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        CircleIconButton(
                          icon: LucideIcons.ellipsis,
                          label: 'More options',
                          onPressed: () => _more(context, session),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatDayAndTime(session.startedAt),
                      style: context.text.labelMedium?.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(session.title, style: context.text.headlineLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${formatClock(session.duration)} · ${session.flags.length} ${session.flags.length == 1 ? 'flag' : 'flags'} · ',
                          style: context.text.bodySmall,
                        ),
                        Icon(LucideIcons.lock, size: 12, color: c.muted),
                        const SizedBox(width: 4),
                        Text('On this phone', style: context.text.bodySmall),
                      ],
                    ),
                    if (session.summary != null) ...[
                      const SizedBox(height: 14),
                      Text(session.summary!, style: context.text.bodyMedium),
                    ],
                    const SizedBox(height: 24),
                    _Player(state: state, session: session),
                    const SizedBox(height: 24),
                    _Tabs(
                      tab: state.tab,
                      flagCount: session.flags.length,
                      onChanged: cubit.showTab,
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, ?current],
                      ),
                      child: state.tab == ReviewTab.flags
                          ? _FlagList(
                              key: const ValueKey('flags'),
                              state: state,
                              session: session,
                            )
                          : _Transcript(
                              key: const ValueKey('transcript'),
                              session: session,
                            ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.paddingOf(context).bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: c.bg,
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GoldButton(
                            label: 'Share with a lawyer',
                            icon: LucideIcons.userPlus,
                            height: 54,
                            onPressed: cubit.share,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleIconButton(
                          icon: LucideIcons.messageSquare,
                          label: 'Ask LegAI about this conversation',
                          size: 54,
                          onPressed: () => Navigator.of(context).pushNamed(
                            Routes.chat,
                            arguments: ChatArgs(
                              initialQuestion:
                                  'I had a ${session.topic.label.toLowerCase()} conversation. ${session.summary ?? ''} What should I do next?',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Player extends StatelessWidget {
  const _Player({required this.state, required this.session});
  final ReviewState state;
  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<ReviewCubit>();
    final total = state.duration.inMilliseconds;
    final peaks = state.peaks.isEmpty
        ? List<double>.filled(52, 0.15)
        : state.peaks;
    final bars = [
      for (var i = 0; i < peaks.length; i++)
        WaveBar(
          peaks[i],
          tone: (i + 0.5) / peaks.length <= state.progress
              ? WaveBarTone.played
              : WaveBarTone.idle,
        ),
    ];
    final markers = [
      if (total > 0)
        for (final f in session.flags)
          WaveMarker(
            f.at.inMilliseconds / total,
            emphasised: f.id == state.openFlagId,
          ),
    ];

    return Row(
      children: [
        Semantics(
          button: true,
          label: state.playing ? 'Pause recording' : 'Play recording',
          child: Material(
            color: state.hasAudio ? c.gold : c.surface2,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: cubit.togglePlay,
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  state.playing ? LucideIcons.pause : LucideIcons.play,
                  size: 18,
                  color: state.hasAudio ? c.onGold : c.muted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              WaveformBars(
                bars: bars,
                height: 48,
                playhead: state.hasAudio ? state.progress : null,
                markers: markers,
                onSeek: state.hasAudio ? cubit.seekFraction : null,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatClock(state.position), style: _timeStyle(context)),
                  Text(formatClock(state.duration), style: _timeStyle(context)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle? _timeStyle(BuildContext context) =>
      context.text.labelSmall?.copyWith(
        color: context.colors.muted,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.tab,
    required this.flagCount,
    required this.onChanged,
  });
  final ReviewTab tab;
  final int flagCount;
  final ValueChanged<ReviewTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(ReviewTab t, String label) {
      final selected = tab == t;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: ShapeDecoration(
              color: selected ? c.surface : Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onChanged(t),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      label,
                      style: context.text.labelMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: c.surface2,
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          item(ReviewTab.flags, 'Flags · $flagCount'),
          const SizedBox(width: 4),
          item(ReviewTab.transcript, 'Transcript'),
        ],
      ),
    );
  }
}

class _FlagList extends StatelessWidget {
  const _FlagList({super.key, required this.state, required this.session});
  final ReviewState state;
  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReviewCubit>();
    if (session.flags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'LegAI didn\'t flag anything in this conversation.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(fontSize: 14),
        ),
      );
    }
    return Column(
      children: [
        for (final f in session.flags)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FlagTile(
              flag: f,
              expanded: state.openFlagId == f.id,
              onToggle: () => cubit.toggleFlag(f.id),
              onPlay: () => cubit.playFlag(f),
              onHear: () => cubit.hearAdvice(f),
              onAsk: () => Navigator.of(context).pushNamed(
                Routes.chat,
                arguments: ChatArgs(
                  initialQuestion: '${f.title} What should I do?',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({super.key, required this.session});
  final ListenSession session;

  @override
  Widget build(BuildContext context) {
    final flagged = session.flags
        .map((f) => f.segmentId)
        .whereType<String>()
        .toSet();
    if (session.segments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No speech was transcribed.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in session.segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TranscriptLine(segment: s, flagged: flagged.contains(s.id)),
          ),
      ],
    );
  }
}
