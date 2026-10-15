/// Turns backend auth errors into messages people can act on.
abstract final class AuthErrorMapper {
  static String friendly(String error) {
    final e = error.toLowerCase();
    if (e.contains('invalid login credentials')) {
      return 'The email or password you entered is incorrect.';
    }
    if (e.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (e.contains('user already registered') ||
        e.contains('already been registered')) {
      return 'This email is already registered. Please log in instead.';
    }
    if (e.contains('password should be at least')) {
      return 'Your password must be at least 6 characters long.';
    }
    if (e.contains('invalid email') || e.contains('unable to validate email')) {
      return 'Please enter a valid email address.';
    }
    if (e.contains('connection') ||
        e.contains('network') ||
        e.contains('socket')) {
      return 'No internet connection. Please check your network.';
    }
    if (e.contains('timeout') || e.contains('timed out')) {
      return 'The request timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
