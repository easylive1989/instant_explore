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

/// Today's daily story for the current app language. `null` if no story
/// has been published yet (e.g. brand-new install + cron hasn't run).
final todayDailyStoryProvider = FutureProvider<DailyStory?>((ref) async {
  final language = ref.watch(currentLanguageProvider);
  final repo = ref.watch(dailyStoryRepositoryProvider);
  return repo.fetchToday(language: dbLanguageOf(language));
});

/// Today's daily story keyed by the DB [language] string (e.g. `'zh-TW'`).
///
/// Used by [DailyStoryCard] so it can resolve the language from
/// [EasyLocalization] context rather than [currentLanguageProvider], which
/// makes widget tests simpler to set up.
final todayDailyStoryByLanguageProvider =
    FutureProvider.family<DailyStory?, String>((ref, language) async {
      final repo = ref.watch(dailyStoryRepositoryProvider);
      return repo.fetchToday(language: language);
    });

/// History list — last 30 days strictly before today.
final dailyStoryHistoryProvider = FutureProvider<List<DailyStory>>((ref) async {
  final language = ref.watch(currentLanguageProvider);
  final repo = ref.watch(dailyStoryRepositoryProvider);
  // Use start-of-today so today's story is included via fetchToday only.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return repo.fetchHistory(
    language: dbLanguageOf(language),
    before: today,
    limit: 30,
  );
});
