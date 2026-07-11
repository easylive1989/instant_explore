import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds an explore [Place] from a [DailyStory] so the daily-story screen can
/// reuse the on-demand generation page (`/config`) for the SAME place.
///
/// Bridges daily_story → explore by building a [Place] from a [DailyStory];
/// cross-feature domain imports are allowed by the dependency rules.
///
/// Returns null when [DailyStory.wikidataId] is missing — generation requires
/// a `wikidata:`-prefixed id, so the caller should hide the CTA instead.
Place? placeFromDailyStory(DailyStory story) {
  final wikidataId = story.wikidataId;
  if (wikidataId == null) return null;
  final imageUrl = story.imageUrl;
  return Place(
    id: 'wikidata:$wikidataId',
    name: story.placeName,
    address: story.placeLocation,
    // Coordinates are unused by hook/narration generation and by the
    // /config screen UI; a placeholder keeps the value object valid.
    location: const PlaceLocation(latitude: 0, longitude: 0),
    tags: const [],
    photos: imageUrl != null
        ? [
            PlacePhoto(
              url: imageUrl,
              width: 0,
              height: 0,
              attributions: const [],
            ),
          ]
        : const [],
    // Daily story places are UNESCO World Heritage Sites.
    category: PlaceCategory.historicalCultural,
  );
}

/// Navigates to the on-demand generation page for the daily story's place.
///
/// No-op when the place can't be built (missing wikidata id) — callers should
/// already gate on that, this is a defensive guard.
void launchSamePlaceStories(BuildContext context, DailyStory story) {
  final place = placeFromDailyStory(story);
  if (place == null) return;
  context.push('/config', extra: place);
}
