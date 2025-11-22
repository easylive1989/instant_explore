/// Application-wide constant values.
///
/// Contains general constants used throughout the application.
class AppConstants {
  AppConstants._();

  /// Supabase table names
  static const String diaryEntriesTable = 'diary_entries';
  static const String diaryTagsTable = 'diary_tags';
  static const String diaryEntryTagsTable = 'diary_entry_tags';
  static const String diaryImagesTable = 'diary_images';

  /// Supabase storage buckets
  static const String diaryImagesBucket = 'diary-images';

  /// Date and time formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'yyyy年MM月dd日';
  static const String displayDateTimeFormat = 'yyyy年MM月dd日 HH:mm';
  static const String displayTimeFormat = 'HH:mm';

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Image constraints
  static const int imageQuality = 85;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1920;

  /// Rating constraints
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int defaultRating = 3;

  /// Search constraints
  static const int minSearchQueryLength = 2;
  static const int maxSearchResults = 20;

  /// Tag constraints
  static const int maxTagLength = 20;
  static const int maxTagsPerDiary = 10;

  /// Diary constraints
  static const int maxTitleLength = 100;
  static const int maxContentLength = 5000;
}
