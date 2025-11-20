/// Formatting utility functions.
///
/// Provides formatting utilities for numbers, text, and other data types.
class FormatUtils {
  FormatUtils._();

  /// Format distance in meters to human-readable format
  ///
  /// Returns "XXm" for distances < 1000m, "X.Xkm" for longer distances
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Format rating to display string with star emoji
  ///
  /// Example: 4.5 -> "⭐ 4.5"
  static String formatRating(double rating) {
    return '⭐ ${rating.toStringAsFixed(1)}';
  }

  /// Format price level to display string
  ///
  /// Converts numeric price level (1-4) to dollar signs ($-$$$$)
  static String formatPriceLevel(int? priceLevel) {
    if (priceLevel == null) return '未知';
    return '\$' * priceLevel;
  }

  /// Format file size in bytes to human-readable format
  ///
  /// Example: 1024 -> "1.0 KB", 1048576 -> "1.0 MB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }

  /// Truncate text to specified length with ellipsis
  ///
  /// Example: truncate("Hello World", 8) -> "Hello..."
  static String truncate(
    String text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Capitalize first letter of a string
  ///
  /// Example: "hello" -> "Hello"
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Format a list of tags to comma-separated string
  ///
  /// Example: ["food", "好吃"] -> "#food, #好吃"
  static String formatTags(List<String> tags) {
    if (tags.isEmpty) return '';
    return tags.map((tag) => '#$tag').join(', ');
  }

  /// Format count with abbreviation for large numbers
  ///
  /// Example: 1500 -> "1.5K", 1500000 -> "1.5M"
  static String formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(1)}K';
    } else {
      final m = count / 1000000;
      return '${m.toStringAsFixed(1)}M';
    }
  }

  /// Format percentage
  ///
  /// Example: 0.856 -> "85.6%"
  static String formatPercentage(double value, {int decimals = 1}) {
    final percentage = value * 100;
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Format phone number (basic format for display)
  ///
  /// Example: "0912345678" -> "0912-345-678"
  static String formatPhoneNumber(String phone) {
    if (phone.length == 10 && phone.startsWith('09')) {
      return '${phone.substring(0, 4)}-${phone.substring(4, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  /// Extract initials from a name
  ///
  /// Example: "John Doe" -> "JD"
  static String getInitials(String name, {int maxLength = 2}) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';

    final initials = words
        .take(maxLength)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return initials;
  }
}
