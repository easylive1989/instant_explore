import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

abstract class DailyStoryRepository {
  /// Returns the most recent published story in [language] whose
  /// `publish_date` is on or before today (Asia/Taipei). Returns `null`
  /// if no row exists yet (e.g. the cron job hasn't run for the first time).
  Future<DailyStory?> fetchToday({required String language});

  /// Returns up to [limit] stories in [language] strictly older than
  /// [before], ordered by `publish_date` descending. Used for the history
  /// screen with simple "load more" pagination.
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  });
}
