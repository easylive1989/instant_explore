import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyStoryDetailScreen extends StatelessWidget {
  final DailyStory story;
  const DailyStoryDetailScreen({super.key, required this.story});

  static const _historyRoute = '/daily-story/history';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('daily_story.detail_title'.tr()),
        actions: [
          TextButton(
            onPressed: () => context.push(_historyRoute),
            child: Text('daily_story.detail_history_button'.tr()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (story.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: story.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(story.placeName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            _MetaRow(
              label: 'daily_story.detail_location_label'.tr(),
              value: story.placeLocation,
            ),
            _MetaRow(
              label: 'daily_story.detail_era_label'.tr(),
              value: story.era,
            ),
            const SizedBox(height: 16),
            Text(story.story, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openWikipedia(context),
              icon: const Icon(Icons.open_in_new),
              label: Text('daily_story.detail_read_more_wikipedia'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWikipedia(BuildContext context) async {
    final uri = Uri.parse(story.wikipediaUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
