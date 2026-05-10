import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDailyStoryRepository implements DailyStoryRepository {
  final SupabaseClient _client;

  SupabaseDailyStoryRepository(this._client);

  static const _table = 'daily_stories';

  @override
  Future<DailyStory?> fetchToday({required String language}) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('language', language)
        .order('publish_date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('language', language)
        .lt('publish_date', _isoDate(before))
        .order('publish_date', ascending: false)
        .limit(limit);
    return rows.map(_fromRow).toList();
  }

  static DailyStory _fromRow(Map<String, dynamic> row) {
    return DailyStory(
      publishDate: DateTime.parse(row['publish_date'] as String),
      language: row['language'] as String,
      placeName: row['place_name'] as String,
      placeLocation: row['place_location'] as String,
      era: row['era'] as String,
      story: row['story'] as String,
      imageUrl: row['image_url'] as String?,
      wikipediaUrl: row['wikipedia_url'] as String,
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
