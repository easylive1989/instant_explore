import 'package:travel_diary/core/constants/app_constants.dart';

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

  /// Validate diary title
  static String? validateDiaryTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入標題';
    }
    if (value.length > AppConstants.maxTitleLength) {
      return '標題不能超過 ${AppConstants.maxTitleLength} 個字元';
    }
    return null;
  }

  /// Validate diary content
  static String? validateDiaryContent(String? value) {
    if (value != null && value.length > AppConstants.maxContentLength) {
      return '內容不能超過 ${AppConstants.maxContentLength} 個字元';
    }
    return null;
  }

  /// Validate tag name
  static String? validateTagName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入標籤名稱';
    }
    if (value.length > AppConstants.maxTagLength) {
      return '標籤不能超過 ${AppConstants.maxTagLength} 個字元';
    }
    if (!RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$').hasMatch(value)) {
      return '標籤只能包含中文、英文、數字和底線';
    }
    return null;
  }

  /// Validate rating value
  static bool isValidRating(int? rating) {
    if (rating == null) return false;
    return rating >= AppConstants.minRating && rating <= AppConstants.maxRating;
  }

  /// Validate search query
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入搜尋關鍵字';
    }
    if (value.length < AppConstants.minSearchQueryLength) {
      return '搜尋關鍵字至少需要 ${AppConstants.minSearchQueryLength} 個字元';
    }
    return null;
  }

  /// Check if a string is not empty or whitespace
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Check if a string exceeds max length
  static bool exceedsMaxLength(String? value, int maxLength) {
    if (value == null) return false;
    return value.length > maxLength;
  }

  /// Validate latitude
  static bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat >= -90 && lat <= 90;
  }

  /// Validate longitude
  static bool isValidLongitude(double? lng) {
    if (lng == null) return false;
    return lng >= -180 && lng <= 180;
  }

  /// Validate coordinates
  static bool isValidCoordinates(double? lat, double? lng) {
    return isValidLatitude(lat) && isValidLongitude(lng);
  }

  /// Sanitize user input (remove leading/trailing whitespace, normalize)
  static String sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
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
