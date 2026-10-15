import 'package:equatable/equatable.dart';

enum ActivityKind { listenIn, ask, talk }

/// One row in "Recent" and in Sessions.
class RecentActivity extends Equatable {
  const RecentActivity({
    required this.id,
    required this.kind,
    required this.title,
    required this.date,
    this.length,
    this.flagCount = 0,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final DateTime date;
  final Duration? length;
  final int flagCount;

  @override
  List<Object?> get props => [id, kind, title, date, length, flagCount];
}
