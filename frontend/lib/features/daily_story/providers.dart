import 'package:context_app/features/daily_story/data/supabase_daily_story_repository.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/repositories/daily_story_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for daily stories. Override in tests with the in-memory fake.
final dailyStoryRepositoryProvider = Provider<DailyStoryRepository>((ref) {
  return SupabaseDailyStoryRepository(Supabase.instance.client);
});

/// Maps the app's [Language] model to the DB `language` column value.
///
/// The P2 cron writes either `'zh-TW'` or `'en'`; the app's
/// [Language.english] uses `'en-US'`, so we normalise here.
String dbLanguageOf(Language language) {
  if (language == Language.traditionalChinese) return 'zh-TW';
  return 'en';
}

/// The latest published daily story for the current app language. `null` if
/// no story has been published yet (e.g. brand-new install + cron hasn't run).
///
/// If today's story hasn't been generated, this naturally falls back to the
/// most recent prior day's story.
final latestDailyStoryProvider = FutureProvider<DailyStory?>((ref) async {
  final language = ref.watch(currentLanguageProvider);
  final repo = ref.watch(dailyStoryRepositoryProvider);
  return repo.fetchLatest(language: dbLanguageOf(language));
});

/// Latest daily story keyed by the DB [language] string (e.g. `'zh-TW'`).
///
/// Used by [DailyStoryCard] so it can resolve the language from
/// [EasyLocalization] context rather than [currentLanguageProvider], which
/// makes widget tests simpler to set up.
final latestDailyStoryByLanguageProvider =
    FutureProvider.family<DailyStory?, String>((ref, language) async {
      final repo = ref.watch(dailyStoryRepositoryProvider);
      return repo.fetchLatest(language: language);
    });

/// History list — up to 30 stories strictly older than the latest one (which
/// is already shown on the card). Falls back to "before today" if there is no
/// latest story yet.
final dailyStoryHistoryProvider = FutureProvider<List<DailyStory>>((ref) async {
  final language = ref.watch(currentLanguageProvider);
  final repo = ref.watch(dailyStoryRepositoryProvider);
  final dbLanguage = dbLanguageOf(language);
  final latest = await repo.fetchLatest(language: dbLanguage);
  final before = latest?.publishDate ?? _startOfToday();
  return repo.fetchHistory(language: dbLanguage, before: before, limit: 30);
});

/// History list keyed by the DB [language] string. Used by
/// [DailyStoryHistoryScreen] for the same testability reason as
/// [latestDailyStoryByLanguageProvider].
final dailyStoryHistoryByLanguageProvider =
    FutureProvider.family<List<DailyStory>, String>((ref, language) async {
      final repo = ref.watch(dailyStoryRepositoryProvider);
      final latest = await repo.fetchLatest(language: language);
      final before = latest?.publishDate ?? _startOfToday();
      return repo.fetchHistory(language: language, before: before, limit: 30);
    });

DateTime _startOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
