import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/motion.dart';
import '../../../settings/domain/entities/jurisdiction.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_widgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _menu(BuildContext context) async {
    final bloc = context.read<ChatBloc>();
    if (bloc.state.conversation == null) return;
    final ok = await confirm(
      context,
      title: 'Delete this conversation?',
      message: 'It will be removed from this phone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) bloc.add(const ChatDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (a, b) =>
          a.messages.length != b.messages.length ||
          a.error != b.error ||
          a.status != b.status,
      listener: (context, state) {
        if (state.status == ChatStatus.deleted) {
          Navigator.of(context).maybePop();
          return;
        }
        if (state.error != null) {
          showLegaiSnack(
            context,
            state.error!,
            icon: LucideIcons.triangleAlert,
          );
        }
        _scrollToEnd();
      },
      builder: (context, state) {
        final convo = state.conversation;
        final jurisdiction = Jurisdictions.byCode(convo?.jurisdictionCode);
        final messages = state.messages;
        final lastAssistant = messages.isNotEmpty && !messages.last.isUser
            ? messages.last
            : null;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  title: convo?.title ?? 'Ask',
                  subtitle: 'Ask · ${jurisdiction.name} law',
                  onMore: convo == null ? null : () => _menu(context),
                ),
                Divider(color: c.line),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: messages.isEmpty && !state.isThinking
                            ? _EmptyState(
                                onPick: (q) => context.read<ChatBloc>().add(
                                  ChatMessageSent(q),
                                ),
                              )
                            : _MessageList(
                                controller: _scroll,
                                state: state,
                                lastAssistantFollowUps:
                                    lastAssistant?.answer?.followUps ??
                                    const [],
                              ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.paddingOf(context).bottom + 12,
                        child: ChatComposer(
                          enabled: !state.isThinking,
                          onSend: (t) =>
                              context.read<ChatBloc>().add(ChatMessageSent(t)),
                          onVoice: () => Navigator.of(
                            context,
                          ).pushReplacementNamed(Routes.voice),
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

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.state,
    required this.lastAssistantFollowUps,
  });

  final ScrollController controller;
  final ChatState state;
  final List<String> lastAssistantFollowUps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final messages = state.messages;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        if (messages.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${formatRelativeDay(messages.first.createdAt)}, ${DateFormat.Hm().format(messages.first.createdAt)}',
                style: context.text.labelSmall?.copyWith(
                  color: c.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        for (final m in messages)
          Padding(
            key: ValueKey(m.id),
            padding: const EdgeInsets.only(bottom: 18),
            child: FadeSlideIn(
              child: m.isUser
                  ? UserBubble(text: m.text)
                  : AssistantMessage(
                      message: m,
                      speaking: state.speakingMessageId == m.id,
                      onReadAloud: () => context.read<ChatBloc>().add(
                        ChatReadAloudToggled(m.id),
                      ),
                      onRegenerate: () => context.read<ChatBloc>().add(
                        ChatAnswerRegenerated(m.id),
                      ),
                    ),
            ),
          ),
        if (state.isThinking)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Row(
              children: [AssistantAvatar(), SizedBox(width: 12), TypingDots()],
            ),
          ),
        if (!state.isThinking && lastAssistantFollowUps.isNotEmpty)
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: SuggestionChips(
              suggestions: lastAssistantFollowUps,
              onTap: (q) => context.read<ChatBloc>().add(ChatMessageSent(q)),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.onMore});
  final String title;
  final String subtitle;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          CircleIconButton(
            icon: LucideIcons.chevronLeft,
            label: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                Text(
                  subtitle,
                  style: context.text.labelSmall?.copyWith(
                    color: c.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Opacity(
            opacity: onMore == null ? 0 : 1,
            child: CircleIconButton(
              icon: LucideIcons.trash2,
              label: 'Delete conversation',
              onPressed: onMore,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});
  final ValueChanged<String> onPick;

  static const _examples = [
    'Do I have to answer police questions?',
    'Can my employer cut my salary?',
    'Can my landlord keep my deposit?',
    'Is a verbal agreement binding?',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
      children: [
        const Center(child: AssistantAvatar()),
        const SizedBox(height: 16),
        Text(
          'What would you like to know?',
          textAlign: TextAlign.center,
          style: context.text.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Describe what happened in your own words. LegAI explains your rights and the law behind them.',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: c.muted),
        ),
        const SizedBox(height: 24),
        for (final q in _examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: c.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPick(q),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(q, style: context.text.titleSmall)),
                      Icon(LucideIcons.arrowUpRight, size: 18, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
