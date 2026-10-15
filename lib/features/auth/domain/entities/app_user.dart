import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    this.email,
    this.name,
    this.isGuest = false,
  });

  final String id;
  final String? email;
  final String? name;

  /// True when the app runs without a backend (no Supabase keys).
  final bool isGuest;

  /// First name for greetings, falling back to the email's local part.
  String? get firstName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n.split(RegExp(r'\s+')).first;
    final e = email;
    if (e == null || !e.contains('@')) return null;
    final local = e.split('@').first.split(RegExp(r'[._-]')).first;
    if (local.isEmpty) return null;
    return local[0].toUpperCase() + local.substring(1);
  }

  /// Up to two initials for the avatar.
  String get initials {
    final source = (name?.trim().isNotEmpty ?? false)
        ? name!
        : (firstName ?? '');
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'L';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => [id, email, name, isGuest];
}
