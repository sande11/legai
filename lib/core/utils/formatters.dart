import 'package:intl/intl.dart';

/// `12:48`, or `1:02:05` past an hour.
String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// `18 min`, `45 s`, `1 h 05 min`.
String formatLength(Duration d) {
  if (d.inMinutes < 1) return '${d.inSeconds} s';
  if (d.inHours < 1) return '${d.inMinutes} min';
  return '${d.inHours} h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')} min';
}

/// `Today`, `Yesterday`, `Mon`, or `12 Sep`.
String formatRelativeDay(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(date);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat.E().format(date);
  return DateFormat('d MMM').format(date);
}

/// `Today · 16:05`.
String formatDayAndTime(DateTime date, {DateTime? now}) =>
    '${formatRelativeDay(date, now: now)} · ${DateFormat.Hm().format(date)}';

String greetingFor(DateTime time) {
  final h = time.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
