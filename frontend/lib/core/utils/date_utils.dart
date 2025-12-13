import 'package:intl/intl.dart';
import 'package:context_app/core/constants/app_constants.dart';

/// Date and time utility functions.
///
/// Provides formatting and parsing utilities for dates and times.
class DateUtils {
  DateUtils._();

  /// Format a DateTime to display date format (yyyy年MM月dd日)
  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Format a DateTime to display date-time format (yyyy年MM月dd日 HH:mm)
  static String formatDisplayDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.displayDateTimeFormat).format(dateTime);
  }

  /// Format a DateTime to display time only (HH:mm)
  static String formatDisplayTime(DateTime dateTime) {
    return DateFormat(AppConstants.displayTimeFormat).format(dateTime);
  }

  /// Format a DateTime to ISO date format (yyyy-MM-dd)
  static String formatIsoDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format a DateTime to ISO date-time format (yyyy-MM-dd HH:mm:ss)
  static String formatIsoDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  /// Parse an ISO date string (yyyy-MM-dd) to DateTime
  static DateTime? parseIsoDate(String dateString) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse an ISO date-time string (yyyy-MM-dd HH:mm:ss) to DateTime
  static DateTime? parseIsoDateTime(String dateTimeString) {
    try {
      return DateFormat(AppConstants.dateTimeFormat).parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Format a DateTime to relative time (e.g., "2小時前", "3天前")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months個月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分鐘前';
    } else {
      return '剛剛';
    }
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get the start of day (00:00:00) for a given date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of day (23:59:59) for a given date
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
