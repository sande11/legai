import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../audio/domain/speech_services.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/chat_usecases.dart';

// Events ---------------------------------------------------------------------

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  const ChatOpened({this.conversationId, this.initialQuestion});
  final String? conversationId;
  final String? initialQuestion;
  @override
  List<Object?> get props => [conversationId, initialQuestion];
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

class ChatAnswerRegenerated extends ChatEvent {
  const ChatAnswerRegenerated(this.messageId);
  final String messageId;
  @override
  List<Object?> get props => [messageId];
}

class ChatReadAloudToggled extends ChatEvent {
  const ChatReadAloudToggled(this.messageId);
  final String messageId;
  @override
  List<Object?> get props => [messageId];
}

class ChatDeleted extends ChatEvent {
  const ChatDeleted();
}

class _ReadAloudFinished extends ChatEvent {
  const _ReadAloudFinished();
}

// State ----------------------------------------------------------------------

enum ChatStatus { loading, ready, thinking, deleted }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.conversation,
    this.error,
    this.speakingMessageId,
  });

  final ChatStatus status;
  final Conversation? conversation;
  final String? error;
  final String? speakingMessageId;

  List<ChatMessage> get messages => conversation?.messages ?? const [];
  bool get isThinking => status == ChatStatus.thinking;

  ChatState copyWith({
    ChatStatus? status,
    Conversation? conversation,
    String? error,
    bool clearError = false,
    String? speakingMessageId,
    bool clearSpeaking = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      error: clearError ? null : (error ?? this.error),
      speakingMessageId: clearSpeaking
          ? null
          : (speakingMessageId ?? this.speakingMessageId),
    );
  }

  @override
  List<Object?> get props => [status, conversation, error, speakingMessageId];
}

// Bloc -----------------------------------------------------------------------

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required AskLegalQuestion askLegalQuestion,
    required GetConversation getConversation,
    required SaveConversation saveConversation,
    required DeleteConversation deleteConversation,
    required SpeechSynthesizer synthesizer,
    required String Function() jurisdictionCode,
    this._uuid = const Uuid(),
    DateTime Function()? clock,
  }) : _ask = askLegalQuestion,
       _get = getConversation,
       _save = saveConversation,
       _delete = deleteConversation,
       _tts = synthesizer,
       _jurisdiction = jurisdictionCode,
       _now = clock ?? DateTime.now,
       super(const ChatState()) {
    on<ChatOpened>(_onOpened);
    on<ChatMessageSent>(_onSent);
    on<ChatAnswerRegenerated>(_onRegenerate);
    on<ChatReadAloudToggled>(_onReadAloud);
    on<_ReadAloudFinished>(
      (e, emit) => emit(state.copyWith(clearSpeaking: true)),
    );
    on<ChatDeleted>(_onDeleted);
  }

  final AskLegalQuestion _ask;
  final GetConversation _get;
  final SaveConversation _save;
  final DeleteConversation _delete;
  final SpeechSynthesizer _tts;
  final String Function() _jurisdiction;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<void> _onOpened(ChatOpened e, Emitter<ChatState> emit) async {
    final id = e.conversationId;
    if (id != null) {
      final existing = await _get(id);
      emit(state.copyWith(status: ChatStatus.ready, conversation: existing));
    } else {
      emit(state.copyWith(status: ChatStatus.ready));
    }
    final q = e.initialQuestion;
    if (q != null && q.trim().isNotEmpty) add(ChatMessageSent(q));
  }

  Future<void> _onSent(ChatMessageSent e, Emitter<ChatState> emit) async {
    final text = e.text.trim();
    if (text.isEmpty || state.isThinking) return;
    final now = _now();
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: text,
      createdAt: now,
    );
    final base =
        state.conversation ??
        Conversation(
          id: _uuid.v4(),
          title: titleFromQuestion(text),
          messages: const [],
          updatedAt: now,
          jurisdictionCode: _jurisdiction(),
        );
    final withQuestion = base.copyWith(
      messages: [...base.messages, userMessage],
      updatedAt: now,
    );
    emit(
      state.copyWith(
        status: ChatStatus.thinking,
        conversation: withQuestion,
        clearError: true,
      ),
    );
    await _answer(text, withQuestion, emit);
  }

  Future<void> _onRegenerate(
    ChatAnswerRegenerated e,
    Emitter<ChatState> emit,
  ) async {
    final convo = state.conversation;
    if (convo == null || state.isThinking) return;
    final index = convo.messages.indexWhere((m) => m.id == e.messageId);
    if (index <= 0) return;
    final question = convo.messages
        .sublist(0, index)
        .lastWhere((m) => m.isUser, orElse: () => convo.messages.first);
    final trimmed = convo.copyWith(messages: convo.messages.sublist(0, index));
    emit(
      state.copyWith(
        status: ChatStatus.thinking,
        conversation: trimmed,
        clearError: true,
      ),
    );
    await _answer(question.text, trimmed, emit);
  }

  Future<void> _answer(
    String question,
    Conversation convo,
    Emitter<ChatState> emit,
  ) async {
    try {
      final answer = await _ask(
        AskParams(
          question: question,
          jurisdictionCode: convo.jurisdictionCode,
          history: convo.messages,
        ),
      );
      final reply = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        text: answer.summary,
        createdAt: _now(),
        answer: answer,
      );
      final updated = convo.copyWith(
        messages: [...convo.messages, reply],
        updatedAt: _now(),
      );
      emit(state.copyWith(status: ChatStatus.ready, conversation: updated));
      await _save(updated);
    } on Failure catch (f) {
      emit(state.copyWith(status: ChatStatus.ready, error: f.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: ChatStatus.ready,
          error: const UnexpectedFailure().message,
        ),
      );
    }
  }

  Future<void> _onReadAloud(
    ChatReadAloudToggled e,
    Emitter<ChatState> emit,
  ) async {
    if (state.speakingMessageId == e.messageId) {
      await _tts.stop();
      emit(state.copyWith(clearSpeaking: true));
      return;
    }
    final message = state.messages
        .where((m) => m.id == e.messageId)
        .firstOrNull;
    final text = message?.answer?.spokenText ?? message?.text;
    if (text == null) return;
    await _tts.stop();
    emit(state.copyWith(speakingMessageId: e.messageId));
    unawaited(
      _tts.speak(text).whenComplete(() {
        if (!isClosed && state.speakingMessageId == e.messageId) {
          add(const _ReadAloudFinished());
        }
      }),
    );
  }

  Future<void> _onDeleted(ChatDeleted e, Emitter<ChatState> emit) async {
    final id = state.conversation?.id;
    if (id != null) await _delete(id);
    emit(state.copyWith(status: ChatStatus.deleted));
  }

  @override
  Future<void> close() async {
    if (state.speakingMessageId != null) await _tts.stop();
    return super.close();
  }
}
