class AuthErrorHandler {
  static String getFriendlyMessage(String error) {
    // Supabase Auth Errors
    if (error.contains('Invalid login credentials')) {
      return 'The email or password you entered is incorrect';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please verify your email before logging in';
    }
    if (error.contains('User already registered')) {
      return 'This email is already registered. Please log in instead';
    }
    if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long';
    }
    if (error.contains('Invalid email address')) {
      return 'Please enter a valid email address';
    }
    
    // Network/Generic Errors
    if (error.contains('Connection error') || 
        error.contains('Network is unreachable')) {
      return 'No internet connection. Please check your network';
    }
    if (error.contains('Timeout')) {
      return 'Request timed out. Please try again';
    }
    
    // Default fallback
    return 'Something went wrong. Please try again';
  }
}