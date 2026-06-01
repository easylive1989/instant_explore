import 'package:equatable/equatable.dart';

/// A daily-place story shown to the user once per day in their app language.
///
/// Mirrors a row in Supabase `public.daily_stories` joined with the matching
/// `daily_story_places` row. One day has one `DailyStory` per supported
/// language (zh-TW, en).
class DailyStory extends Equatable {
  /// Date this story was published / shown to users (Asia/Taipei calendar).
  final DateTime publishDate;

  /// Language tag matching the app locale: `zh-TW` or `en`.
  final String language;

  /// Localised place name (e.g. "羅馬競技場" or "Colosseum").
  final String placeName;

  /// Localised location string (e.g. "義大利羅馬" or "Rome, Italy").
  final String placeLocation;

  /// Approximate era of the story (e.g. "公元 70-80 年" or "70-80 CE").
  final String era;

  /// Legacy plain-text body, joined from [cardParagraphs] when card fields
  /// are present. Kept as a fallback for old App versions and as the body
  /// the legacy layout renders when [cardParagraphs] is null.
  final String story;

  /// Optional image URL (Wikipedia thumbnail). May be null.
  final String? imageUrl;

  /// Wikipedia article URL in the matching language; falls back to en.
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

  /// Wikidata Q-id of the place (e.g. "Q10285"), joined from
  /// `daily_story_places`. Null when the place hasn't been resolved yet;
  /// the App hides the "explore more stories" CTA in that case.
  final String? wikidataId;

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
    this.wikidataId,
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
    wikidataId,
  ];
}
