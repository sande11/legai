import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/waveform_bars.dart';
import '../bloc/live_listen_bloc.dart';
import '../widgets/advice_widgets.dart';

class LiveListenPage extends StatelessWidget {
  const LiveListenPage({super.key});

  void _minimise(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<LiveListenBloc, LiveListenState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) async {
        final bloc = context.read<LiveListenBloc>();
        if (state.status == LiveStatus.saved && state.savedSessionId != null) {
          await Navigator.of(context).pushReplacementNamed(
            Routes.review,
            arguments: ReviewArgs(state.savedSessionId!),
          );
          bloc.add(const LiveReset());
        } else if (state.status == LiveStatus.failed) {
          await showErrorDialog(
            context,
            state.error ?? 'Listen In stopped unexpectedly.',
            title: 'Couldn\'t listen in',
          );
          bloc.add(const LiveReset());
          if (context.mounted) _minimise(context);
        }
      },
      builder: (context, state) {
        final bloc = context.read<LiveListenBloc>();
        final expanded = state.transcriptExpanded;
        final flaggedSegments = state.flags
            .map((f) => f.segmentId)
            .whereType<String>()
            .toSet();
        final topic = state.setup?.topic.label ?? 'Conversation';

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header ------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: LucideIcons.chevronDown,
                        label: 'Minimise. LegAI keeps listening',
                        onPressed: () => _minimise(context),
                      ),
                      Expanded(
                        child: _RecordingClock(state: state, topic: topic),
                      ),
                      CircleIconButton(
                        icon: LucideIcons.headphones,
                        label: state.privateOutput
                            ? 'Earbuds connected'
                            : 'No earbuds connected',
                        selected: state.privateOutput,
                        background: state.privateOutput
                            ? c.goldSoft
                            : c.surface,
                        borderColor: state.privateOutput ? c.goldLine : c.line,
                        foreground: state.privateOutput ? c.goldIcon : c.muted,
                        onPressed: () => showLegaiSnack(
                          context,
                          state.privateOutput
                              ? 'Advice is whispered to your earbuds. Only you can hear it.'
                              : 'Connect earbuds to hear advice privately.',
                          icon: LucideIcons.headphones,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.notice != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _Notice(
                      text: state.notice!,
                      onClose: () => bloc.add(const LiveNoticeDismissed()),
                    ),
                  ),

                // Waveform + transcript ----------------------------------------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, box) => TweenAnimationBuilder<double>(
                        // Animate only the open/close toggle; size changes from the
                        // layout (e.g. the advice card growing) apply at once.
                        tween: Tween(end: expanded ? 1 : 0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) {
                          // Scale the meter to the space left, so small phones still fit.
                          final h = box.maxHeight;
                          double mix(double closed, double open) =>
                              closed + (open - closed) * t;
                          // Collapsed: leave room for the header and the latest line,
                          // and give the rest to the meter.
                          final closedTop = (h * 0.1).clamp(0.0, 40.0);
                          final closedBottom = (h * 0.06).clamp(0.0, 28.0);
                          final closedMeter =
                              (h - 48 - 72 - closedTop - closedBottom).clamp(
                                0.0,
                                130.0,
                              );
                          final meter = mix(
                            closedMeter,
                            (h * 0.18).clamp(0.0, 60.0),
                          );
                          final top = mix(
                            closedTop,
                            (h * 0.05).clamp(0.0, 16.0),
                          );
                          final bottom = mix(closedBottom, 6);
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: top,
                                  bottom: bottom,
                                ),
                                child: SizedBox(
                                  height: meter < 24 ? 0 : meter,
                                  child: meter < 24
                                      ? null
                                      : WaveformBars(
                                          bars: state.bars,
                                          height: meter,
                                          barWidth: 3,
                                        ),
                                ),
                              ),
                              _TranscriptHeader(
                                expanded: expanded,
                                onToggle: () =>
                                    bloc.add(const LiveTranscriptToggled()),
                              ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: Alignment.topLeft,
                                    children: [...previous, ?current],
                                  ),
                                  child: expanded
                                      ? _TranscriptList(
                                          key: const ValueKey('list'),
                                          state: state,
                                          flagged: flaggedSegments,
                                        )
                                      : SingleChildScrollView(
                                          key: const ValueKey('latest'),
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: state.latestSegment == null
                                                ? Text(
                                                    state.status ==
                                                            LiveStatus.starting
                                                        ? 'Starting…'
                                                        : 'Waiting for the conversation to begin…',
                                                    style: context
                                                        .text
                                                        .bodyLarge
                                                        ?.copyWith(
                                                          color: c.muted,
                                                        ),
                                                  )
                                                : TranscriptLine(
                                                    segment:
                                                        state.latestSegment!,
                                                    live: !state
                                                        .latestSegment!
                                                        .isFinal,
                                                    flagged: flaggedSegments
                                                        .contains(
                                                          state
                                                              .latestSegment!
                                                              .id,
                                                        ),
                                                  ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Advice card --------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: state.shownFlag == null
                        ? _ListeningHint(
                            key: const ValueKey('hint'),
                            active: state.isActive,
                          )
                        : AdviceCard(
                            key: ValueKey(state.shownFlag!.id),
                            flag: state.shownFlag!,
                            earlierCount: state.earlierFlagCount,
                            onHearAgain: () => bloc.add(
                              LiveAdviceReplayed(state.shownFlag!.id),
                            ),
                            onAsk: () => Navigator.of(context).pushNamed(
                              Routes.chat,
                              arguments: ChatArgs(
                                initialQuestion:
                                    '${state.shownFlag!.title} What should I do?',
                              ),
                            ),
                            onEarlier: () => bloc.add(const LiveAdviceCycled()),
                          ),
                  ),
                ),

                // Controls -----------------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Control(
                        label: state.isPaused ? 'Resume' : 'Pause',
                        child: CircleIconButton(
                          icon: state.isPaused
                              ? LucideIcons.play
                              : LucideIcons.pause,
                          label: state.isPaused ? 'Resume' : 'Pause',
                          size: 56,
                          onPressed: state.isActive
                              ? () => bloc.add(const LivePauseToggled())
                              : null,
                        ),
                      ),
                      const SizedBox(width: 30),
                      _Control(
                        label: 'End & review',
                        child: Semantics(
                          button: true,
                          label: 'End and review',
                          child: Material(
                            color: c.text,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: state.isActive
                                  ? () => bloc.add(const LiveStopRequested())
                                  : null,
                              child: SizedBox.square(
                                dimension: 76,
                                child: Center(
                                  child: state.status == LiveStatus.saving
                                      ? SizedBox.square(
                                          dimension: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: c.red,
                                          ),
                                        )
                                      : Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: c.red,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      _Control(
                        label: state.marks.isEmpty
                            ? 'Mark'
                            : 'Marked ${state.marks.length}',
                        child: CircleIconButton(
                          icon: LucideIcons.flag,
                          label: 'Mark this moment',
                          size: 56,
                          background: state.marks.isEmpty ? c.surface : c.gold,
                          foreground: state.marks.isEmpty ? c.text : c.onGold,
                          borderColor: state.marks.isEmpty ? c.line : c.gold,
                          onPressed: state.isActive
                              ? () {
                                  bloc.add(const LiveMarkPressed());
                                  showLegaiSnack(
                                    context,
                                    'Moment marked at ${formatClock(state.elapsed)}',
                                    icon: LucideIcons.flag,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
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

class _RecordingClock extends StatelessWidget {
  const _RecordingClock({required this.state, required this.topic});
  final LiveListenState state;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paused = state.isPaused;
    final label = switch (state.status) {
      LiveStatus.starting => 'STARTING',
      LiveStatus.saving => 'SAVING',
      LiveStatus.paused => 'PAUSED',
      _ => 'REC',
    };
    return Semantics(
      label: '$label ${formatClock(state.elapsed)}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingDot(
                  color: paused ? c.muted : c.red,
                  active: state.status == LiveStatus.recording,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: paused ? c.muted : c.red,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatClock(state.elapsed),
                  style: context.text.titleMedium?.copyWith(
                    fontSize: 18,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.lock, size: 12, color: c.muted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Saved on this phone · $topic',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: c.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptHeader extends StatelessWidget {
  const _TranscriptHeader({required this.expanded, required this.onToggle});
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(
          'TRANSCRIPT',
          style: context.text.labelSmall?.copyWith(
            color: c.muted,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          expanded: expanded,
          label: expanded ? 'Hide transcript' : 'Show full transcript',
          child: ExcludeSemantics(
            child: TextButton(
              onPressed: onToggle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(expanded ? 'Hide' : 'Show'),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(LucideIcons.chevronDown, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptList extends StatelessWidget {
  const _TranscriptList({
    super.key,
    required this.state,
    required this.flagged,
  });
  final LiveListenState state;
  final Set<String> flagged;

  @override
  Widget build(BuildContext context) {
    final segments = state.segments.reversed.toList();
    if (segments.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Nothing transcribed yet.',
          style: context.text.bodyLarge?.copyWith(color: context.colors.muted),
        ),
      );
    }
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0, 0.12],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView.separated(
        reverse: true,
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        itemCount: segments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final s = segments[i];
          return TranscriptLine(
            key: ValueKey(s.id),
            segment: s,
            live: !s.isFinal,
            flagged: flagged.contains(s.id),
          );
        },
      ),
    );
  }
}

class _ListeningHint extends StatelessWidget {
  const _ListeningHint({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.goldSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.shield, size: 18, color: c.goldIcon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              active
                  ? 'LegAI is listening. Advice appears here when something needs your attention.'
                  : 'Listen In has stopped.',
              style: context.text.bodySmall?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.onClose});
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: c.goldSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.goldLine),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.volume2, size: 16, color: c.goldIcon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: context.text.bodySmall?.copyWith(color: c.text),
              ),
            ),
            IconButton(
              onPressed: onClose,
              tooltip: 'Dismiss',
              icon: Icon(LucideIcons.x, size: 16, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          SizedBox(height: 76, child: Center(child: child)),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Text(
              label,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
