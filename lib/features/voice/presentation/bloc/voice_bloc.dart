import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../audio/domain/speech_services.dart';
import '../../../chat/domain/entities/chat_entities.dart';
import '../../../chat/domain/usecases/chat_usecases.dart';
import '../../../settings/domain/entities/jurisdiction.dart';

// Events ---------------------------------------------------------------------

sealed class VoiceEvent extends Equatable {
  const VoiceEvent();
  @override
  List<Object?> get props => [];
}

class VoiceStarted extends VoiceEvent {
  const VoiceStarted();
}

/// The big button: start, finish, or interrupt depending on the state.
class VoiceMicPressed extends VoiceEvent {
  const VoiceMicPressed();
}

class _Recognized extends VoiceEvent {
  const _Recognized(this.update);
  final RecognitionUpdate update;
  @override
  List<Object?> get props => [update];
}

class _ListenEnded extends VoiceEvent {
  const _ListenEnded({this.error});
  final String? error;
}

class _LevelChanged extends VoiceEvent {
  const _LevelChanged(this.level);
  final double level;
  @override
  List<Object?> get props => [level];
}

class _SpokenUpTo extends VoiceEvent {
  const _SpokenUpTo(this.end);
  final int end;
  @override
  List<Object?> get props => [end];
}

class _SpeakingDone extends VoiceEvent {
  const _SpeakingDone();
}

// State ----------------------------------------------------------------------

enum VoiceStatus {
  initializing,
  idle,
  listening,
  thinking,
  speaking,
  unavailable,
}

class VoiceState extends Equatable {
  const VoiceState({
    this.status = VoiceStatus.initializing,
    this.heard = '',
    this.answer,
    this.spokenEnd = 0,
    this.level = 0,
    this.message,
  });

  final VoiceStatus status;

  /// What the person said.
  final String heard;

  /// What LegAI is saying.
  final LegalAnswer? answer;

  /// Character offset reached while speaking, for the caption highlight.
  final int spokenEnd;

  /// Microphone level 0–1.
  final double level;

  /// Hint or error under the orb.
  final String? message;

  VoiceState copyWith({
    VoiceStatus? status,
    String? heard,
    LegalAnswer? answer,
    bool clearAnswer = false,
    int? spokenEnd,
    double? level,
    String? message,
    bool clearMessage = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      heard: heard ?? this.heard,
      answer: clearAnswer ? null : (answer ?? this.answer),
      spokenEnd: spokenEnd ?? this.spokenEnd,
      level: level ?? this.level,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, heard, answer, spokenEnd, level, message];
}

// Bloc -----------------------------------------------------------------------

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc({
    required this._recognizer,
    required SpeechSynthesizer synthesizer,
    required AskLegalQuestion askLegalQuestion,
    required SaveConversation saveConversation,
    required String Function() jurisdictionCode,
    this._uuid = const Uuid(),
  }) : _tts = synthesizer,
       _ask = askLegalQuestion,
       _save = saveConversation,
       _jurisdiction = jurisdictionCode,
       super(const VoiceState()) {
    on<VoiceStarted>(_onStarted);
    on<VoiceMicPressed>(_onMic);
    on<_Recognized>((e, emit) => emit(state.copyWith(heard: e.update.text)));
    on<_LevelChanged>((e, emit) {
      if (state.status == VoiceStatus.listening) {
        emit(state.copyWith(level: e.level));
      }
    });
    on<_ListenEnded>(_onListenEnded);
    on<_SpokenUpTo>((e, emit) => emit(state.copyWith(spokenEnd: e.end)));
    on<_SpeakingDone>(_onSpeakingDone);
  }

  final SpeechRecognizer _recognizer;
  final SpeechSynthesizer _tts;
  final AskLegalQuestion _ask;
  final SaveConversation _save;
  final String Function() _jurisdiction;
  final Uuid _uuid;

  StreamSubscription<RecognitionUpdate>? _listenSub;
  StreamSubscription<double>? _levelSub;
  StreamSubscription<SpeechProgress>? _progressSub;
  Conversation? _conversation;

  Jurisdiction get _place => Jurisdictions.byCode(_jurisdiction());

  Future<void> _onStarted(VoiceStarted e, Emitter<VoiceState> emit) async {
    final ok = await _recognizer.initialize();
    await _tts.configure(locale: _place.speechLocale);
    _levelSub = _recognizer.soundLevels.listen((l) => add(_LevelChanged(l)));
    _progressSub = _tts.progress.listen((p) => add(_SpokenUpTo(p.end)));
    if (!ok) {
      emit(
        state.copyWith(
          status: VoiceStatus.unavailable,
          message:
              'Speech recognition isn\'t available. Check microphone and speech permissions in Settings.',
        ),
      );
      return;
    }
    _startListening(emit);
  }

  Future<void> _onMic(VoiceMicPressed e, Emitter<VoiceState> emit) async {
    switch (state.status) {
      case VoiceStatus.listening:
        await _recognizer.stop();
      case VoiceStatus.speaking:
        await _tts.stop();
        _startListening(emit);
      case VoiceStatus.idle:
        _startListening(emit);
      case VoiceStatus.unavailable:
        add(const VoiceStarted());
      case VoiceStatus.thinking:
      case VoiceStatus.initializing:
        break;
    }
  }

  void _startListening(Emitter<VoiceState> emit) {
    _listenSub?.cancel();
    emit(
      state.copyWith(
        status: VoiceStatus.listening,
        heard: '',
        clearAnswer: true,
        spokenEnd: 0,
        clearMessage: true,
      ),
    );
    _listenSub = _recognizer
        .listen(localeId: _place.speechLocale)
        .listen(
          (u) => add(_Recognized(u)),
          onError: (Object err) => add(_ListenEnded(error: err.toString())),
          onDone: () => add(const _ListenEnded()),
        );
  }

  Future<void> _onListenEnded(_ListenEnded e, Emitter<VoiceState> emit) async {
    if (state.status != VoiceStatus.listening) return;
    final question = state.heard.trim();
    if (question.isEmpty) {
      emit(
        state.copyWith(
          status: VoiceStatus.idle,
          level: 0,
          message: e.error == null
              ? 'I didn\'t catch that. Tap the mic and try again.'
              : 'Something interrupted the microphone. Tap to try again.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: VoiceStatus.thinking,
        level: 0,
        clearMessage: true,
      ),
    );
    try {
      final answer = await _ask(
        AskParams(
          question: question,
          jurisdictionCode: _place.code,
          history: _conversation?.messages ?? const [],
        ),
      );
      emit(
        state.copyWith(
          status: VoiceStatus.speaking,
          answer: answer,
          spokenEnd: 0,
        ),
      );
      await _remember(question, answer);
      unawaited(
        _tts.speak(answer.spokenText).whenComplete(() {
          if (!isClosed) add(const _SpeakingDone());
        }),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: VoiceStatus.idle, message: f.message));
    }
  }

  void _onSpeakingDone(_SpeakingDone e, Emitter<VoiceState> emit) {
    if (state.status != VoiceStatus.speaking) return;
    emit(
      state.copyWith(
        status: VoiceStatus.idle,
        spokenEnd: state.answer?.spokenText.length ?? 0,
      ),
    );
  }

  Future<void> _remember(String question, LegalAnswer answer) async {
    final now = DateTime.now();
    final base =
        _conversation ??
        Conversation(
          id: _uuid.v4(),
          title: titleFromQuestion(question),
          messages: const [],
          updatedAt: now,
          jurisdictionCode: _place.code,
          channel: ConversationChannel.voice,
        );
    final updated = base.copyWith(
      updatedAt: now,
      messages: [
        ...base.messages,
        ChatMessage(
          id: _uuid.v4(),
          role: MessageRole.user,
          text: question,
          createdAt: now,
        ),
        ChatMessage(
          id: _uuid.v4(),
          role: MessageRole.assistant,
          text: answer.summary,
          createdAt: now,
          answer: answer,
        ),
      ],
    );
    _conversation = updated;
    try {
      await _save(updated);
    } on Failure {
      // Saving history is best-effort; the conversation still works.
    }
  }

  @override
  Future<void> close() async {
    await _listenSub?.cancel();
    await _levelSub?.cancel();
    await _progressSub?.cancel();
    await _recognizer.cancel();
    await _tts.stop();
    return super.close();
  }
}
