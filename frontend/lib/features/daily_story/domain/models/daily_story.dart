import 'package:equatable/equatable.dart';

/// A daily-place story shown to the user once per day in their app language.
///
/// Mirrors a row in Supabase `public.daily_stories`. One day has one
/// `DailyStory` per supported language (zh-TW, en).
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

  /// The story body itself (~300-500 chars).
  final String story;

  /// Optional image URL (Wikipedia thumbnail). May be null.
  final String? imageUrl;

  /// Wikipedia article URL in the matching language; falls back to en.
  final String wikipediaUrl;

  const DailyStory({
    required this.publishDate,
    required this.language,
    required this.placeName,
    required this.placeLocation,
    required this.era,
    required this.story,
    required this.imageUrl,
    required this.wikipediaUrl,
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
  ];
}
