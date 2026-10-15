import 'package:equatable/equatable.dart';

import 'jurisdiction.dart';

enum ThemePreference { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.jurisdictionCode = 'MW',
    this.announceRecording = true,
    this.whisperAdvice = true,
  });

  final ThemePreference theme;
  final String jurisdictionCode;

  /// Listen In: say "This conversation is being recorded" when it starts.
  final bool announceRecording;

  /// Listen In: speak new advice through earbuds when they're connected.
  final bool whisperAdvice;

  Jurisdiction get jurisdiction => Jurisdictions.byCode(jurisdictionCode);

  AppSettings copyWith({
    ThemePreference? theme,
    String? jurisdictionCode,
    bool? announceRecording,
    bool? whisperAdvice,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      jurisdictionCode: jurisdictionCode ?? this.jurisdictionCode,
      announceRecording: announceRecording ?? this.announceRecording,
      whisperAdvice: whisperAdvice ?? this.whisperAdvice,
    );
  }

  @override
  List<Object?> get props => [
    theme,
    jurisdictionCode,
    announceRecording,
    whisperAdvice,
  ];
}
