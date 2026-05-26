import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Home-screen preview when the story has the full card_* fields.
///
/// Shows cardTitle as the main heading (replacing placeName) and the
/// first ~60 chars of paragraph 1 as a teaser. Deliberately omits the
/// drop-cap / Roman year / pull quote — those belong to the detail page.
class CardPreviewCard extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;
  const CardPreviewCard({super.key, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstParagraph = story.cardParagraphs!.first;
    final teaser = firstParagraph.characters.length > 60
        ? '${firstParagraph.characters.take(60)}…'
        : firstParagraph;

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
                    story.cardTitle!,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    story.cardTitleSub!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teaser,
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
