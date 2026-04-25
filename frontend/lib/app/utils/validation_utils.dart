/// Validation utility functions.
///
/// Provides validation logic for various types of user input.
class ValidationUtils {
  ValidationUtils._();

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Check if a string is not empty or whitespace
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate password strength (medium requirement: 8+ chars, uppercase, lowercase, number)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.required';
    }

    if (value.length < 8) {
      return 'validation.passwordTooShort';
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'validation.passwordNoUppercase';
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'validation.passwordNoLowercase';
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'validation.passwordNoNumber';
    }

    return null;
  }

  /// Validate password confirmation matches
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'validation.required';
    }

    if (value != password) {
      return 'auth.passwordMismatch';
    }

    return null;
  }

  /// Validate email for authentication
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.required';
    }

    if (!isValidEmail(value.trim())) {
      return 'validation.emailInvalid';
    }

    return null;
  }
}
