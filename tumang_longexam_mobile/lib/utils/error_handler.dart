class ErrorHandler {
  /// Converts technical error messages to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Authentication errors
    if (errorString.contains('401') ||
        errorString.contains('404') ||
        errorString.contains('unauthorized') ||
        errorString.contains('invalid credentials') ||
        errorString.contains('authentication failed') ||
        errorString.contains('user not found') ||
        errorString.contains('invalid email or password')) {
      return 'Invalid email or password';
    }

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network error. Please check your connection';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('internal server error')) {
      return 'Server error. Please try again later';
    }

    // Not found errors (excluding authentication 404s)
    if (errorString.contains('not found') &&
        !errorString.contains('user not found')) {
      return 'Resource not found';
    }

    // Validation errors
    if (errorString.contains('400') || errorString.contains('bad request')) {
      if (errorString.contains('email')) {
        return 'Invalid email format';
      }
      if (errorString.contains('password')) {
        return 'Password must be at least 6 characters';
      }
      if (errorString.contains('username')) {
        return 'Username already exists';
      }
      return 'Invalid input. Please check your information';
    }

    // Registration specific errors
    if (errorString.contains('email already exists') ||
        errorString.contains('duplicate email')) {
      return 'Email already registered';
    }

    if (errorString.contains('username already exists') ||
        errorString.contains('duplicate username')) {
      return 'Username already taken';
    }

    // Wishlist/Inquiry errors
    if (errorString.contains('wishlist')) {
      return 'Unable to update wishlist';
    }

    if (errorString.contains('inquiry')) {
      return 'Unable to send inquiry';
    }

    // Generic fallback
    return 'Something went wrong. Please try again';
  }

  /// Gets a simple error message for common scenarios
  static String getSimpleMessage(String context) {
    switch (context.toLowerCase()) {
      case 'login':
        return 'Invalid email or password';
      case 'signup':
      case 'register':
        return 'Registration failed. Please try again';
      case 'wishlist':
        return 'Unable to update wishlist';
      case 'inquiry':
        return 'Unable to send inquiry';
      case 'profile':
        return 'Unable to load profile';
      case 'items':
        return 'Unable to load items';
      default:
        return 'Something went wrong. Please try again';
    }
  }
}
