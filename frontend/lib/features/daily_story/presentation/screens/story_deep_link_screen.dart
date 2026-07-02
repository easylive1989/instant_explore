import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:context_app/shared/widgets/redirect_to_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a `/:locale/story/:date` universal link to the matching daily
/// story and shows [DailyStoryDetailScreen]. Falls back to home when the
/// link is malformed or the story does not exist.
class StoryDeepLinkScreen extends ConsumerWidget {
  final String locale;
  final String date;

  const StoryDeepLinkScreen({
    super.key,
    required this.locale,
    required this.date,
  });

  static bool _validLocale(String l) => l == 'zh' || l == 'en';

  static DateTime? _parseDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    return DateTime.tryParse(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedDate = _parseDate(date);
    if (!_validLocale(locale) || parsedDate == null) {
      return const RedirectToHome();
    }
    final language = locale == 'zh' ? 'zh-TW' : 'en';
    final story = ref.watch(
      dailyStoryByDateProvider((language: language, date: parsedDate)),
    );
    return story.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const RedirectToHome(),
      data: (value) {
        if (value == null) {
          return const RedirectToHome();
        }
        return DailyStoryDetailScreen(story: value);
      },
    );
  }
}
