import 'package:equatable/equatable.dart';

/// A daily-place story shown to the user once per day in their app language.
///
/// Mirrors a row in Supabase `public.daily_stories` joined with the matching
/// `daily_story_places` row. One day has one `DailyStory` per supported
/// language (zh-TW, en).
class DailyStory extends Equatable {
  final DateTime publishDate;
  final String language;
  final String placeName;
  final String placeLocation;
  final String era;

  /// Legacy plain-text body, joined from [cardParagraphs] when card fields
  /// are present. Kept as a fallback for old App versions and as the body
  /// the legacy layout renders when [cardParagraphs] is null.
  final String story;

  final String? imageUrl;
  final String wikipediaUrl;

  // Card content fields (story-level). All nullable so the App can fall
  // back to the legacy layout when any of cardTitle / cardTitleSub /
  // cardParagraphs is missing.
  final String? cardTitle;
  final String? cardTitleSub;
  final List<String>? cardParagraphs;
  final String? cardPullQuote;
  final String? cardPullQuoteAttrib;
  final String? cardAnnoRoman;

  // Card location fields (place-level, joined from daily_story_places).
  // Decorative — the card layout renders without them if null.
  final String? cardLocationEn;
  final String? cardCityCh;
  final String? cardCityEn;

  const DailyStory({
    required this.publishDate,
    required this.language,
    required this.placeName,
    required this.placeLocation,
    required this.era,
    required this.story,
    required this.imageUrl,
    required this.wikipediaUrl,
    this.cardTitle,
    this.cardTitleSub,
    this.cardParagraphs,
    this.cardPullQuote,
    this.cardPullQuoteAttrib,
    this.cardAnnoRoman,
    this.cardLocationEn,
    this.cardCityCh,
    this.cardCityEn,
  });

  @override
  List<Object?> get props => [
    publishDate,
    language,
    placeName,
    placeLocation,
    era,
    story,
    imageUrl,
    wikipediaUrl,
    cardTitle,
    cardTitleSub,
    cardParagraphs,
    cardPullQuote,
    cardPullQuoteAttrib,
    cardAnnoRoman,
    cardLocationEn,
    cardCityCh,
    cardCityEn,
  ];
}
