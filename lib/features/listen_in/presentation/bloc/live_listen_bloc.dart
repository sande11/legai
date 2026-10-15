import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/waveform_bars.dart';
import '../../../audio/domain/speech_services.dart';
import '../../../settings/domain/entities/jurisdiction.dart';
import '../../domain/entities/listen_entities.dart';
import '../../domain/repositories/listen_repositories.dart';
import '../../domain/services/transcript_assembler.dart';
import '../../domain/usecases/listen_in_usecases.dart';

// Events ---------------------------------------------------------------------

sealed class LiveListenEvent extends Equatable {
  const LiveListenEvent();
  @override
  List<Object?> get props => [];
}

class LiveStarted extends LiveListenEvent {
  const LiveStarted(this.setup);
  final ListenSetup setup;
  @override
  List<Object?> get props => [setup];
}

class LivePauseToggled extends LiveListenEvent {
  const LivePauseToggled();
}

class LiveMarkPressed extends LiveListenEvent {
  const LiveMarkPressed();
}

class LiveTranscriptToggled extends LiveListenEvent {
  const LiveTranscriptToggled();
}

class LiveAdviceReplayed extends LiveListenEvent {
  const LiveAdviceReplayed(this.flagId);
  final String flagId;
  @override
  List<Object?> get props => [flagId];
}

/// Steps back through earlier advice on the card.
class LiveAdviceCycled extends LiveListenEvent {
  const LiveAdviceCycled();
}

class LiveNoticeDismissed extends LiveListenEvent {
  const LiveNoticeDismissed();
}

class LiveStopRequested extends LiveListenEvent {
  const LiveStopRequested();
}

/// After the review screen has opened, return to idle.
class LiveReset extends LiveListenEvent {
  const LiveReset();
}

class _CaptureUpdated extends LiveListenEvent {
  const _CaptureUpdated(this.update);
  final CaptureUpdate update;
}

class _Ticked extends LiveListenEvent {
  const _Ticked();
}

class _LevelSampled extends LiveListenEvent {
  const _LevelSampled(this.level);
  final double level;
}

class _FlagsFound extends LiveListenEvent {
  const _FlagsFound(this.flags);
  final List<AdviceFlag> flags;
}

class _FlagWhispered extends LiveListenEvent {
  const _FlagWhispered(this.flagId);
  final String flagId;
}

class _Interrupted extends LiveListenEvent {
  const _Interrupted(this.paused);
  final bool paused;
}

// State ----------------------------------------------------------------------

enum LiveStatus { idle, starting, recording, paused, saving, saved, failed }

class LiveListenState extends Equatable {
  const LiveListenState({
    this.status = LiveStatus.idle,
    this.setup,
    this.startedAt,
    this.elapsed = Duration.zero,
    this.segments = const [],
    this.flags = const [],
    this.shownFlagId,
    this.bars = const [],
    this.marks = const [],
    this.transcriptExpanded = false,
    this.privateOutput = false,
    this.notice,
    this.savedSessionId,
    this.error,
  });

  final LiveStatus status;
  final ListenSetup? setup;
  final DateTime? startedAt;
  final Duration elapsed;
  final List<TranscriptSegment> segments;
  final List<AdviceFlag> flags;

  /// The flag on the advice card.
  final String? shownFlagId;

  /// Rolling microphone meter.
  final List<WaveBar> bars;
  final List<Duration> marks;
  final bool transcriptExpanded;

  /// Earbuds or headphones connected.
  final bool privateOutput;

  /// One-off message, e.g. "tell everyone you're recording".
  final String? notice;
  final String? savedSessionId;
  final String? error;

  bool get isActive =>
      status == LiveStatus.starting ||
      status == LiveStatus.recording ||
      status == LiveStatus.paused;
  bool get isPaused => status == LiveStatus.paused;

  AdviceFlag? get shownFlag {
    final id = shownFlagId;
    if (id == null) return null;
    for (final f in flags) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Flags before the one on the card.
  int get earlierFlagCount {
    final id = shownFlagId;
    if (id == null) return 0;
    return flags.indexWhere((f) => f.id == id).clamp(0, flags.length);
  }

  TranscriptSegment? get latestSegment =>
      segments.isEmpty ? null : segments.last;

  LiveListenState copyWith({
    LiveStatus? status,
    ListenSetup? setup,
    DateTime? startedAt,
    Duration? elapsed,
    List<TranscriptSegment>? segments,
    List<AdviceFlag>? flags,
    String? shownFlagId,
    List<WaveBar>? bars,
    List<Duration>? marks,
    bool? transcriptExpanded,
    bool? privateOutput,
    String? notice,
    bool clearNotice = false,
    String? savedSessionId,
    String? error,
    bool clearError = false,
  }) {
    return LiveListenState(
      status: status ?? this.status,
      setup: setup ?? this.setup,
      startedAt: startedAt ?? this.startedAt,
      elapsed: elapsed ?? this.elapsed,
      segments: segments ?? this.segments,
      flags: flags ?? this.flags,
      shownFlagId: shownFlagId ?? this.shownFlagId,
      bars: bars ?? this.bars,
      marks: marks ?? this.marks,
      transcriptExpanded: transcriptExpanded ?? this.transcriptExpanded,
      privateOutput: privateOutput ?? this.privateOutput,
      notice: clearNotice ? null : (notice ?? this.notice),
      savedSessionId: savedSessionId ?? this.savedSessionId,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    setup,
    startedAt,
    elapsed,
    segments,
    flags,
    shownFlagId,
    bars,
    marks,
    transcriptExpanded,
    privateOutput,
    notice,
    savedSessionId,
    error,
  ];
}

// Bloc -----------------------------------------------------------------------

/// Runs a Listen In session. Lives at the app root so a conversation keeps
/// recording while the user looks at other screens.
class LiveListenBloc extends Bloc<LiveListenEvent, LiveListenState> {
  LiveListenBloc({
    required this._capture,
    required AnalyzeSegment analyzeSegment,
    required FinishListenSession finishSession,
    required SpeechSynthesizer synthesizer,
    required AudioOutputRoutes outputRoutes,
    this._uuid = const Uuid(),
    this.meterLength = 60,
  }) : _analyze = analyzeSegment,
       _finish = finishSession,
       _tts = synthesizer,
       _routes = outputRoutes,
       super(const LiveListenState()) {
    on<LiveStarted>(_onStarted);
    on<LivePauseToggled>(_onPauseToggled);
    on<LiveMarkPressed>(_onMark);
    on<LiveTranscriptToggled>(
      (e, emit) =>
          emit(state.copyWith(transcriptExpanded: !state.transcriptExpanded)),
    );
    on<LiveAdviceReplayed>(_onReplay);
    on<LiveAdviceCycled>(_onCycle);
    on<LiveNoticeDismissed>(
      (e, emit) => emit(state.copyWith(clearNotice: true)),
    );
    on<LiveStopRequested>(_onStop);
    on<LiveReset>((e, emit) => emit(const LiveListenState()));
    on<_CaptureUpdated>(_onCaptureUpdated);
    on<_Ticked>((e, emit) => emit(state.copyWith(elapsed: _clock.elapsed)));
    on<_LevelSampled>(_onLevel);
    on<_FlagsFound>(_onFlagsFound);
    on<_FlagWhispered>(_onWhispered);
    on<_Interrupted>(_onInterrupted);
  }

  final LiveCaptureRepository _capture;
  final AnalyzeSegment _analyze;
  final FinishListenSession _finish;
  final SpeechSynthesizer _tts;
  final AudioOutputRoutes _routes;
  final Uuid _uuid;
  final int meterLength;

  final _clock = Stopwatch();
  final _assembler = TranscriptAssembler();
  StreamSubscription<CaptureUpdate>? _updatesSub;
  StreamSubscription<bool>? _interruptSub;
  Timer? _ticker;
  Timer? _meter;
  Duration? _glowUntil;
  bool _markerPending = false;
  Future<void> _whisperQueue = Future.value();

  Future<void> _onStarted(LiveStarted e, Emitter<LiveListenState> emit) async {
    if (state.isActive) return;
    final setup = e.setup;
    _assembler.reset();
    _clock
      ..stop()
      ..reset();
    emit(
      LiveListenState(
        status: LiveStatus.starting,
        setup: setup,
        startedAt: DateTime.now(),
        bars: List.filled(meterLength, const WaveBar(0)),
      ),
    );

    try {
      final private = await _routes.hasPrivateOutput();
      emit(state.copyWith(privateOutput: private));
      final place = Jurisdictions.byCode(setup.jurisdictionCode);
      await _tts.configure(locale: place.speechLocale);
      await _tts.prepareForRecording();

      if (setup.announce) {
        if (private) {
          emit(
            state.copyWith(
              notice:
                  'Your earbuds are connected, so LegAI can\'t announce out loud. Tell everyone: "This conversation is being recorded."',
            ),
          );
        } else {
          await _tts.speak('This conversation is being recorded.');
        }
      }

      await _capture.ensurePermission();
      await _capture.start(localeId: place.speechLocale);
    } on Failure catch (f) {
      emit(state.copyWith(status: LiveStatus.failed, error: f.message));
      return;
    } catch (_) {
      emit(
        state.copyWith(
          status: LiveStatus.failed,
          error: 'Couldn\'t start listening. Please try again.',
        ),
      );
      return;
    }

    _updatesSub = _capture.updates.listen((u) => add(_CaptureUpdated(u)));
    _interruptSub = _capture.interruptions.listen((p) => add(_Interrupted(p)));
    _clock.start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const _Ticked()),
    );
    _meter = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      if (state.status == LiveStatus.recording) {
        add(_LevelSampled(await _capture.level()));
      }
    });
    emit(state.copyWith(status: LiveStatus.recording, clearError: true));
  }

  Future<void> _onPauseToggled(
    LivePauseToggled e,
    Emitter<LiveListenState> emit,
  ) async {
    if (state.status == LiveStatus.recording) {
      await _capture.pause();
      _clock.stop();
      emit(state.copyWith(status: LiveStatus.paused, elapsed: _clock.elapsed));
    } else if (state.status == LiveStatus.paused) {
      await _capture.resume();
      _clock.start();
      emit(state.copyWith(status: LiveStatus.recording));
    }
  }

  void _onInterrupted(_Interrupted e, Emitter<LiveListenState> emit) {
    if (e.paused && state.status == LiveStatus.recording) {
      _clock.stop();
      emit(
        state.copyWith(
          status: LiveStatus.paused,
          notice: 'Recording paused by your phone (a call or another app).',
        ),
      );
    } else if (!e.paused && state.status == LiveStatus.paused) {
      _clock.start();
      emit(state.copyWith(status: LiveStatus.recording, clearNotice: true));
    }
  }

  void _onMark(LiveMarkPressed e, Emitter<LiveListenState> emit) {
    if (!state.isActive) return;
    emit(state.copyWith(marks: [...state.marks, _clock.elapsed]));
  }

  void _onCaptureUpdated(_CaptureUpdated e, Emitter<LiveListenState> emit) {
    final segment = _assembler.ingest(e.update, _clock.elapsed);
    if (segment == null) return;
    final segments = [...state.segments];
    final i = segments.indexWhere((s) => s.id == segment.id);
    if (i >= 0) {
      segments[i] = segment;
    } else {
      segments.add(segment);
    }
    emit(state.copyWith(segments: segments));

    if (segment.isFinal) {
      final setup = state.setup!;
      final context = AnalysisContext(
        topic: setup.topic,
        jurisdictionCode: setup.jurisdictionCode,
        alreadyFlagged: state.flags.map((f) => f.key).toSet(),
      );
      _analyze(AnalyzeSegmentParams(segment, context)).then((flags) {
        if (flags.isNotEmpty && !isClosed) add(_FlagsFound(flags));
      }).ignore();
    }
  }

  void _onLevel(_LevelSampled e, Emitter<LiveListenState> emit) {
    final glowing = _glowUntil != null && _clock.elapsed <= _glowUntil!;
    final bar = WaveBar(
      e.level,
      tone: glowing ? WaveBarTone.flagged : WaveBarTone.idle,
      marker: glowing && _markerPending,
    );
    if (bar.marker) _markerPending = false;
    final bars = [...state.bars, bar];
    final trimmed = bars.length > meterLength
        ? bars.sublist(bars.length - meterLength)
        : bars;
    emit(state.copyWith(bars: trimmed));
  }

  Future<void> _onFlagsFound(
    _FlagsFound e,
    Emitter<LiveListenState> emit,
  ) async {
    final known = state.flags.map((f) => f.key).toSet();
    final fresh = e.flags.where((f) => !known.contains(f.key)).toList();
    if (fresh.isEmpty) return;
    _glowUntil = _clock.elapsed + const Duration(seconds: 3);
    _markerPending = true;
    emit(
      state.copyWith(
        flags: [...state.flags, ...fresh],
        shownFlagId: fresh.last.id,
      ),
    );

    if (state.setup?.whisper ?? false) {
      final private = await _routes.hasPrivateOutput();
      if (private != state.privateOutput) {
        emit(state.copyWith(privateOutput: private));
      }
      if (private) {
        for (final flag in fresh) {
          _whisper(flag);
        }
      }
    }
  }

  void _whisper(AdviceFlag flag) {
    _whisperQueue = _whisperQueue
        .then((_) async {
          await _tts.speak(flag.spokenText);
          if (!isClosed) add(_FlagWhispered(flag.id));
        })
        .catchError((_) {});
  }

  void _onWhispered(_FlagWhispered e, Emitter<LiveListenState> emit) {
    emit(
      state.copyWith(
        flags: [
          for (final f in state.flags)
            f.id == e.flagId ? f.copyWith(whispered: true) : f,
        ],
      ),
    );
  }

  Future<void> _onReplay(
    LiveAdviceReplayed e,
    Emitter<LiveListenState> emit,
  ) async {
    final flag = state.flags.where((f) => f.id == e.flagId).firstOrNull;
    if (flag == null) return;
    final private = await _routes.hasPrivateOutput();
    emit(state.copyWith(privateOutput: private));
    if (!private) {
      emit(
        state.copyWith(
          notice:
              'Connect earbuds to hear advice privately. Reading it aloud now would be heard by everyone.',
        ),
      );
      return;
    }
    _whisper(flag);
  }

  void _onCycle(LiveAdviceCycled e, Emitter<LiveListenState> emit) {
    if (state.flags.isEmpty) return;
    final i = state.flags.indexWhere((f) => f.id == state.shownFlagId);
    final prev = i <= 0 ? state.flags.length - 1 : i - 1;
    emit(state.copyWith(shownFlagId: state.flags[prev].id));
  }

  Future<void> _onStop(
    LiveStopRequested e,
    Emitter<LiveListenState> emit,
  ) async {
    if (!state.isActive) return;
    emit(state.copyWith(status: LiveStatus.saving));
    _stopTimers();
    _clock.stop();
    final audioPath = await _capture.stop();
    await _updatesSub?.cancel();
    await _interruptSub?.cancel();
    await _tts.stop();

    final setup = state.setup!;
    final segments = [
      for (final s in state.segments) s.copyWith(isFinal: true),
    ];
    final session = ListenSession(
      id: _uuid.v4(),
      title: '${setup.topic.label} conversation',
      topic: setup.topic,
      startedAt: state.startedAt ?? DateTime.now(),
      duration: _clock.elapsed,
      jurisdictionCode: setup.jurisdictionCode,
      audioPath: audioPath,
      segments: segments,
      flags: state.flags,
      marks: state.marks,
    );
    try {
      final saved = await _finish(session);
      emit(
        state.copyWith(
          status: LiveStatus.saved,
          savedSessionId: saved.id,
          elapsed: _clock.elapsed,
        ),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: LiveStatus.failed, error: f.message));
    }
  }

  void _stopTimers() {
    _ticker?.cancel();
    _meter?.cancel();
    _ticker = null;
    _meter = null;
  }

  @override
  Future<void> close() async {
    _stopTimers();
    await _updatesSub?.cancel();
    await _interruptSub?.cancel();
    if (state.isActive) await _capture.cancel();
    return super.close();
  }
}
