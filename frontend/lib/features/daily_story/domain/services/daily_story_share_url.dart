import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

/// Builds the canonical shareable URL for a [DailyStory].
///
/// Shape: `https://lorescape.app/<lang>/story/<date>?utm_source=...`.
/// `<lang>` collapses the app language tag to its locale segment
/// (`zh-TW` → `zh`, `en` → `en`); `<date>` is `publishDate` as
/// `yyyy-MM-dd`. Phase 2 (web page) and Phase 3 (deep link) resolve
/// this URL; in Phase 1 it is a plain link carried in the share text.
String buildDailyStoryShareUrl(DailyStory story) {
  final lang = story.language.toLowerCase().startsWith('zh') ? 'zh' : 'en';
  final d = story.publishDate;
  final date =
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return 'https://lorescape.app/$lang/story/$date'
      '?utm_source=story_share&utm_medium=app';
}
