import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../audio/domain/speech_services.dart';
import '../../domain/entities/listen_entities.dart';
import '../../domain/usecases/listen_in_usecases.dart';

enum ReviewTab { flags, transcript }

class ReviewState extends Equatable {
  const ReviewState({
    this.loading = true,
    this.session,
    this.peaks = const [],
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.openFlagId,
    this.tab = ReviewTab.flags,
    this.hasAudio = false,
    this.deleted = false,
    this.message,
  });

  final bool loading;
  final ListenSession? session;
  final List<double> peaks;
  final Duration position;
  final Duration duration;
  final bool playing;

  /// All flags start closed so the list stays calm.
  final String? openFlagId;
  final ReviewTab tab;
  final bool hasAudio;
  final bool deleted;
  final String? message;

  double get progress => duration.inMilliseconds == 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  ReviewState copyWith({
    bool? loading,
    ListenSession? session,
    List<double>? peaks,
    Duration? position,
    Duration? duration,
    bool? playing,
    String? openFlagId,
    bool clearOpenFlag = false,
    ReviewTab? tab,
    bool? hasAudio,
    bool? deleted,
    String? message,
    bool clearMessage = false,
  }) {
    return ReviewState(
      loading: loading ?? this.loading,
      session: session ?? this.session,
      peaks: peaks ?? this.peaks,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      openFlagId: clearOpenFlag ? null : (openFlagId ?? this.openFlagId),
      tab: tab ?? this.tab,
      hasAudio: hasAudio ?? this.hasAudio,
      deleted: deleted ?? this.deleted,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    session,
    peaks,
    position,
    duration,
    playing,
    openFlagId,
    tab,
    hasAudio,
    deleted,
    message,
  ];
}

class ReviewCubit extends Cubit<ReviewState> {
  ReviewCubit({
    required this.sessionId,
    required GetListenSession getSession,
    required LoadSessionWaveform loadWaveform,
    required RenameListenSession renameSession,
    required DeleteListenSession deleteSession,
    required ShareListenSession shareSession,
    required this._player,
    required SpeechSynthesizer synthesizer,
  }) : _get = getSession,
       _waveform = loadWaveform,
       _rename = renameSession,
       _delete = deleteSession,
       _share = shareSession,
       _tts = synthesizer,
       super(const ReviewState());

  final String sessionId;
  final GetListenSession _get;
  final LoadSessionWaveform _waveform;
  final RenameListenSession _rename;
  final DeleteListenSession _delete;
  final ShareListenSession _share;
  final RecordingPlayer _player;
  final SpeechSynthesizer _tts;
  final _subs = <StreamSubscription<Object?>>[];

  Future<void> load() async {
    final session = await _get(sessionId);
    if (session == null) {
      emit(
        state.copyWith(
          loading: false,
          message: 'This recording couldn\'t be found.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        loading: false,
        session: session,
        duration: session.duration,
      ),
    );

    final path = session.audioPath;
    if (path != null) {
      try {
        final length = await _player.load(path);
        _subs
          ..add(
            _player.position.listen((p) => emit(state.copyWith(position: p))),
          )
          ..add(
            _player.playing.listen((p) => emit(state.copyWith(playing: p))),
          );
        emit(
          state.copyWith(hasAudio: true, duration: length ?? session.duration),
        );
      } catch (_) {
        emit(state.copyWith(hasAudio: false));
      }
    }
    final peaks = await _waveform(session);
    if (!isClosed) emit(state.copyWith(peaks: peaks));
  }

  Future<void> togglePlay() async {
    if (!state.hasAudio) {
      emit(
        state.copyWith(
          message: 'The audio for this conversation isn\'t on this phone.',
        ),
      );
      return;
    }
    if (state.playing) {
      await _player.pause();
    } else {
      await _tts.stop();
      await _player.play();
    }
  }

  Future<void> seekFraction(double f) async {
    if (!state.hasAudio) return;
    final target = Duration(
      milliseconds: (state.duration.inMilliseconds * f).round(),
    );
    emit(state.copyWith(position: target));
    await _player.seek(target);
  }

  /// Plays from just before the flagged words.
  Future<void> playFlag(AdviceFlag flag) async {
    if (!state.hasAudio) {
      emit(
        state.copyWith(
          message: 'The audio for this conversation isn\'t on this phone.',
        ),
      );
      return;
    }
    final start = flag.at - const Duration(seconds: 3);
    await _player.seek(start.isNegative ? Duration.zero : start);
    await _tts.stop();
    await _player.play();
  }

  Future<void> hearAdvice(AdviceFlag flag) async {
    await _player.pause();
    await _tts.speak(flag.spokenText);
  }

  void toggleFlag(String id) {
    if (state.openFlagId == id) {
      emit(state.copyWith(clearOpenFlag: true));
    } else {
      emit(state.copyWith(openFlagId: id));
    }
  }

  void showTab(ReviewTab tab) => emit(state.copyWith(tab: tab));

  Future<void> rename(String title) async {
    final s = state.session;
    if (s == null) return;
    try {
      final updated = await _rename((s, title));
      emit(state.copyWith(session: updated));
    } on Failure catch (f) {
      emit(state.copyWith(message: f.message));
    }
  }

  Future<void> delete() async {
    await _player.pause();
    await _delete(sessionId);
    emit(state.copyWith(deleted: true));
  }

  Future<void> share() async {
    final s = state.session;
    if (s == null) return;
    await _player.pause();
    try {
      await _share(s);
    } catch (_) {
      emit(state.copyWith(message: 'Couldn\'t open the share sheet.'));
    }
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _tts.stop();
    await _player.dispose();
    return super.close();
  }
}
