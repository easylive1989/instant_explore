import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyStoryHistoryScreen extends ConsumerWidget {
  const DailyStoryHistoryScreen({super.key});

  static const _detailRoute = '/daily-story/detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = _dbLanguageFromLocale(context.locale);
    final asyncStories = ref.watch(
      dailyStoryHistoryByLanguageProvider(language),
    );
    return Scaffold(
      appBar: AppBar(title: Text('daily_story.history_title'.tr())),
      body: asyncStories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text(e.toString())),
        data: (stories) {
          if (stories.isEmpty) {
            return Center(child: Text('daily_story.history_empty'.tr()));
          }
          return ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _HistoryTile(
                story: story,
                onTap: () => context.push(_detailRoute, extra: story),
              );
            },
          );
        },
      ),
    );
  }
}

String _dbLanguageFromLocale(Locale locale) {
  final tag = locale.toLanguageTag();
  if (tag.startsWith('zh')) return 'zh-TW';
  return 'en';
}

class _HistoryTile extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;
  const _HistoryTile({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(story.publishDate);
    return ListTile(
      onTap: onTap,
      title: Text(story.placeName),
      subtitle: Text(dateLabel),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
