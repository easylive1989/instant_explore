import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An editorial feed card showing a single [DailyStory] (Field Journal).
///
/// A rounded hero image, a clay chapter overline, a serif title, a
/// "place · date" line and a two-line serif excerpt. Card fields are used
/// when present, falling back to the legacy place name / plain story body.
class StoryCard extends StatelessWidget {
  final DailyStory story;
  final VoidCallback onTap;

  const StoryCard({super.key, required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final ink3 = tokens?.ink3 ?? cs.onSurfaceVariant;
    final radius = context.tokens.rImg;

    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(story.publishDate);

    final title = story.cardTitle ?? story.placeName;
    final excerpt = story.cardParagraphs?.isNotEmpty == true
        ? story.cardParagraphs!.first
        : story.story;
    // Avoid repeating the place name when it is already the title.
    final dateLine = story.cardTitle != null
        ? '${story.placeName} · $dateLabel'
        : dateLabel;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (story.imageUrl != null)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: context.tokens.e1,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedNetworkImage(
                    imageUrl: story.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: story.imageUrl != null ? 14 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (story.cardAnnoRoman != null) ...[
                  Text(
                    'Anno · ${story.cardAnnoRoman}',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                    letterSpacing: 0.4,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  dateLine,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.4,
                    color: ink3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  excerpt,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 16,
                    height: 1.65,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
