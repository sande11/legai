import 'package:equatable/equatable.dart';

/// A country whose law LegAI answers for.
class Jurisdiction extends Equatable {
  const Jurisdiction({
    required this.code,
    required this.name,
    required this.speechLocale,
    this.recordingRuleSummary,
  });

  /// ISO 3166-1 alpha-2, e.g. `MW`.
  final String code;
  final String name;

  /// Locale used for on-device speech recognition and the spoken voice.
  final String speechLocale;

  /// One-line summary of the local consent rule for recording a
  /// conversation. Leave null until it has been confirmed by counsel; the
  /// app then shows a general reminder instead.
  final String? recordingRuleSummary;

  @override
  List<Object?> get props => [code];
}

abstract final class Jurisdictions {
  static const malawi = Jurisdiction(
    code: 'MW',
    name: 'Malawi',
    speechLocale: 'en-US',
  );

  static const supported = <Jurisdiction>[
    malawi,
    Jurisdiction(code: 'ZM', name: 'Zambia', speechLocale: 'en-US'),
    Jurisdiction(code: 'ZW', name: 'Zimbabwe', speechLocale: 'en-US'),
    Jurisdiction(code: 'ZA', name: 'South Africa', speechLocale: 'en-ZA'),
    Jurisdiction(code: 'KE', name: 'Kenya', speechLocale: 'en-KE'),
    Jurisdiction(code: 'TZ', name: 'Tanzania', speechLocale: 'en-US'),
    Jurisdiction(code: 'UG', name: 'Uganda', speechLocale: 'en-US'),
    Jurisdiction(code: 'NG', name: 'Nigeria', speechLocale: 'en-NG'),
    Jurisdiction(code: 'GH', name: 'Ghana', speechLocale: 'en-US'),
    Jurisdiction(code: 'GB', name: 'United Kingdom', speechLocale: 'en-GB'),
    Jurisdiction(code: 'US', name: 'United States', speechLocale: 'en-US'),
  ];

  static Jurisdiction byCode(String? code) =>
      supported.firstWhere((j) => j.code == code, orElse: () => malawi);
}
