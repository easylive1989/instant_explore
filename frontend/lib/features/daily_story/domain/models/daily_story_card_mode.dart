import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

/// True when the row has the three story-core card fields needed to render
/// the new IG-style layout. Decorative fields (pull quote, Roman year,
/// place-level spine / footer) are NOT part of this check — they degrade
/// individually inside the card layout.
///
/// Treats empty strings the same as null. The backfill script and main job
/// always write non-empty card content; an empty string here would mean
/// data corruption upstream, in which case rendering the legacy layout is
/// safer than a card with a blank title.
extension DailyStoryCardMode on DailyStory {
  bool get hasCardLayout {
    final title = cardTitle;
    final sub = cardTitleSub;
    final paragraphs = cardParagraphs;
    return title != null &&
        title.isNotEmpty &&
        sub != null &&
        sub.isNotEmpty &&
        paragraphs != null &&
        paragraphs.length == 3;
  }
}
