import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../audio/domain/speech_services.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/listen_entities.dart';
import '../../domain/repositories/listen_repositories.dart';

class ListenSetupState extends Equatable {
  const ListenSetupState({
    this.topic = ConversationTopic.work,
    this.announce = true,
    this.whisper = true,
    this.privateOutput = false,
    this.checking = false,
    this.error,
  });

  final ConversationTopic topic;
  final bool announce;
  final bool whisper;
  final bool privateOutput;

  /// Asking for permission.
  final bool checking;
  final String? error;

  ListenSetupState copyWith({
    ConversationTopic? topic,
    bool? announce,
    bool? whisper,
    bool? privateOutput,
    bool? checking,
    String? error,
    bool clearError = false,
  }) {
    return ListenSetupState(
      topic: topic ?? this.topic,
      announce: announce ?? this.announce,
      whisper: whisper ?? this.whisper,
      privateOutput: privateOutput ?? this.privateOutput,
      checking: checking ?? this.checking,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    topic,
    announce,
    whisper,
    privateOutput,
    checking,
    error,
  ];
}

/// The "Before you start" sheet.
class ListenSetupCubit extends Cubit<ListenSetupState> {
  ListenSetupCubit({
    required AppSettings settings,
    required this._capture,
    required AudioOutputRoutes outputRoutes,
  }) : _settings = settings,
       _routes = outputRoutes,
       super(
         ListenSetupState(
           announce: settings.announceRecording,
           whisper: settings.whisperAdvice,
         ),
       );

  final AppSettings _settings;
  final LiveCaptureRepository _capture;
  final AudioOutputRoutes _routes;

  Future<void> refreshOutput() async {
    final private = await _routes.hasPrivateOutput();
    if (!isClosed) emit(state.copyWith(privateOutput: private));
  }

  void selectTopic(ConversationTopic topic) =>
      emit(state.copyWith(topic: topic));
  void setAnnounce(bool on) => emit(state.copyWith(announce: on));
  void setWhisper(bool on) => emit(state.copyWith(whisper: on));

  /// Checks permission. Returns the setup to start with, or null.
  Future<ListenSetup?> confirm() async {
    emit(state.copyWith(checking: true, clearError: true));
    try {
      await _capture.ensurePermission();
      emit(state.copyWith(checking: false));
      return ListenSetup(
        topic: state.topic,
        announce: state.announce,
        whisper: state.whisper,
        jurisdictionCode: _settings.jurisdictionCode,
      );
    } on Failure catch (f) {
      emit(state.copyWith(checking: false, error: f.message));
      return null;
    }
  }
}
