import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

abstract class DailyStoryRepository {
  /// Returns the most recently published story in [language] (highest
  /// `publish_date`). Returns `null` if no row exists yet (e.g. the cron job
  /// hasn't run for the first time).
  ///
  /// Server-side RLS already hides future-dated rows, so this naturally falls
  /// back to yesterday's story when today's hasn't been generated yet.
  Future<DailyStory?> fetchLatest({required String language});

  /// Returns up to [limit] stories in [language] strictly older than
  /// [before], ordered by `publish_date` descending. Used for the history
  /// screen with simple "load more" pagination.
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  });

  /// Returns the story published on [date] in [language], or `null` if none
  /// exists (or the date is future-dated and hidden by RLS). Used by the
  /// `/story/:date` deep link to open a specific day's story.
  Future<DailyStory?> fetchByDate({
    required String language,
    required DateTime date,
  });
}
