import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';

/// In-memory fake repository for widget/integration tests.
///
/// Stories can be seeded via [seed]. `fetchLatest` returns the latest matching
/// row by `publishDate`; `fetchHistory` returns rows strictly older than
/// `before`.
class InMemoryDailyStoryRepository implements DailyStoryRepository {
  final List<DailyStory> _stories = [];

  /// Throw on the next call (for testing error states). Cleared after one use.
  Object? errorOnNextCall;

  void seed(List<DailyStory> stories) {
    _stories
      ..clear()
      ..addAll(stories);
  }

  void clear() {
    _stories.clear();
  }

  @override
  Future<DailyStory?> fetchLatest({required String language}) async {
    _maybeThrow();
    final matching = _stories.where((s) => s.language == language).toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return matching.isEmpty ? null : matching.first;
  }

  @override
  Future<List<DailyStory>> fetchHistory({
    required String language,
    required DateTime before,
    int limit = 30,
  }) async {
    _maybeThrow();
    final matching = _stories
        .where(
          (s) => s.language == language && s.publishDate.isBefore(before),
        )
        .toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return matching.take(limit).toList();
  }

  @override
  Future<DailyStory?> fetchByDate({
    required String language,
    required DateTime date,
  }) async {
    _maybeThrow();
    try {
      return _stories.firstWhere(
        (s) =>
            s.language == language &&
            s.publishDate.year == date.year &&
            s.publishDate.month == date.month &&
            s.publishDate.day == date.day,
      );
    } on StateError {
      return null;
    }
  }

  void _maybeThrow() {
    final err = errorOnNextCall;
    if (err != null) {
      errorOnNextCall = null;
      throw err;
    }
  }
}
