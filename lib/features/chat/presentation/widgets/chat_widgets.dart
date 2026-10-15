import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/legai_mark.dart';
import '../../domain/entities/chat_entities.dart';

class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: c.bubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: SelectableText(
            text,
            style: context.text.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
      ),
    );
  }
}

/// Avatar used beside LegAI's messages.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.goldSoft, shape: BoxShape.circle),
      child: LegaiMark(
        size: 18,
        color: c.goldIcon,
        ringColor: c.goldIcon,
        strokeWidth: 2.2,
      ),
    );
  }
}

class AssistantMessage extends StatelessWidget {
  const AssistantMessage({
    super.key,
    required this.message,
    required this.speaking,
    required this.onReadAloud,
    required this.onRegenerate,
  });

  final ChatMessage message;
  final bool speaking;
  final VoidCallback onReadAloud;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final answer = message.answer ?? LegalAnswer(summary: message.text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssistantAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(answer.summary, style: context.text.bodyMedium),
              if (answer.points.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final p in answer.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 9, right: 10),
                          decoration: BoxDecoration(
                            color: c.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(p, style: context.text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
              for (final s in answer.sources) ...[
                const SizedBox(height: 6),
                SourceCard(source: s),
              ],
              const SizedBox(height: 4),
              Transform.translate(
                offset: const Offset(-12, 0),
                child: Row(
                  children: [
                    _ActionIcon(
                      icon: LucideIcons.copy,
                      label: 'Copy answer',
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: [answer.summary, ...answer.points].join('\n'),
                          ),
                        );
                        showLegaiSnack(context, 'Answer copied');
                      },
                    ),
                    _ActionIcon(
                      icon: LucideIcons.volume2,
                      label: speaking
                          ? 'Stop reading aloud'
                          : 'Read answer aloud',
                      active: speaking,
                      onTap: onReadAloud,
                    ),
                    _ActionIcon(
                      icon: LucideIcons.refreshCw,
                      label: 'Regenerate answer',
                      onTap: onRegenerate,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: speaking
                          ? Text(
                              'Reading aloud…',
                              key: const ValueKey('reading'),
                              style: context.text.labelSmall?.copyWith(
                                color: c.goldText,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'General legal information, not representation.',
                    style: context.text.bodySmall?.copyWith(fontSize: 12),
                  ),
                  if (answer.isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: ShapeDecoration(
                        shape: StadiumBorder(side: BorderSide(color: c.line)),
                      ),
                      child: Text(
                        'Demo answer',
                        style: context.text.labelSmall?.copyWith(
                          color: c.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.source});
  final LegalSource source;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Source: ${source.title}, ${source.detail}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.bookOpen, size: 20, color: c.goldIcon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (source.detail.isNotEmpty)
                    Text(
                      source.detail,
                      style: context.text.bodySmall?.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      isSelected: active,
      style: IconButton.styleFrom(
        backgroundColor: active ? c.goldSoft : Colors.transparent,
        foregroundColor: active ? c.goldIcon : c.muted,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in suggestions)
            ActionChip(
              label: Text(s),
              onPressed: () => onTap(s),
              labelStyle: context.text.labelMedium,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: c.line),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
        ],
      ),
    );
  }
}

/// Text field + voice + send, floating at the bottom of the chat.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onVoice,
    required this.enabled,
  });

  final ValueChanged<String> onSend;
  final VoidCallback onVoice;
  final bool enabled;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.line),
        boxShadow: c.cardShadow.length > 1 ? c.cardShadow : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: context.text.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Ask a legal question…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                hintStyle: context.text.bodyMedium?.copyWith(color: c.muted),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onVoice,
            tooltip: 'Switch to voice',
            icon: Icon(LucideIcons.mic, size: 20, color: c.text),
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
          const SizedBox(width: 2),
          AnimatedScale(
            scale: _hasText ? 1 : 0.86,
            duration: const Duration(milliseconds: 180),
            child: IconButton.filled(
              onPressed: _hasText && widget.enabled ? _send : null,
              tooltip: 'Send',
              style: IconButton.styleFrom(
                backgroundColor: c.gold,
                foregroundColor: c.onGold,
                disabledBackgroundColor: c.surface2,
                disabledForegroundColor: c.muted,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(LucideIcons.arrowUp, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
