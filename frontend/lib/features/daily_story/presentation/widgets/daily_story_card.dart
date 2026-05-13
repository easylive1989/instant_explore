import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyStoryCard extends ConsumerWidget {
  const DailyStoryCard({super.key});

  static const _detailRoute = '/daily-story/detail';
  static const _historyRoute = '/daily-story/history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = _dbLanguageFromLocale(context.locale);
    final asyncStory = ref.watch(latestDailyStoryByLanguageProvider(language));
    return asyncStory.when(
      loading: () => const _LoadingCard(),
      error: (_, __) =>
          _EmptyCard(onPressed: () => context.push(_historyRoute)),
      data: (story) {
        if (story == null) {
          return _EmptyCard(onPressed: () => context.push(_historyRoute));
        }
        return _StoryCard(
          story: story,
          onTap: () => context.push(_detailRoute, extra: story),
        );
      },
    );
  }
}

/// Converts a [Locale] to the DB language string used in `daily_stories`.
String _dbLanguageFromLocale(Locale locale) {
  final tag = locale.toLanguageTag();
  if (tag.startsWith('zh')) return 'zh-TW';
  return 'en';
}

class _StoryCard extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;
  const _StoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: story.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'daily_story.card_label'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.placeName,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story.story,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'daily_story.card_cta'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 120,
        child: Center(child: Text('daily_story.card_loading'.tr())),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback onPressed;
  const _EmptyCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'daily_story.card_empty_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPressed,
                child: Text('daily_story.card_empty_cta'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
