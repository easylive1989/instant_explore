import 'dart:typed_data';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';

/// Builds a [Place] with sensible defaults. Override any field as needed.
Place buildPlace({
  String id = 'place-1',
  String name = 'Test Place',
  String formattedAddress = '123 Test Street',
  double latitude = 25.0,
  double longitude = 121.0,
  PlaceCategory category = PlaceCategory.modernUrban,
  List<PlacePhoto> photos = const [],
  List<String> types = const [],
}) {
  return Place(
    id: id,
    name: name,
    formattedAddress: formattedAddress,
    location: PlaceLocation(latitude: latitude, longitude: longitude),
    types: types,
    photos: photos,
    category: category,
  );
}

/// Builds a [Trip] with sensible defaults.
Trip buildTrip({
  String id = 'trip-1',
  String name = 'Kyoto Adventure',
  DateTime? startDate,
  DateTime? endDate,
  DateTime? createdAt,
}) {
  return Trip(
    id: id,
    name: name,
    startDate: startDate,
    endDate: endDate,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

/// Builds a [NarrationContent] from a raw text body.
NarrationContent buildNarrationContent({
  String text =
      'This is a sample narration body. It has multiple sentences! '
      'The third line rounds it off.',
  Language language = Language.english,
}) {
  return NarrationContent.create(text, language: language);
}

/// Builds a [JourneyEntry] with a deterministic [createdAt].
JourneyEntry buildJourneyEntry({
  String id = 'journey-1',
  Place? place,
  NarrationContent? content,
  Set<NarrationAspect> aspects = const {NarrationAspect.historicalBackground},
  DateTime? createdAt,
  Language language = Language.english,
  String? tripId,
}) {
  final resolvedPlace = place ?? buildPlace();
  final resolvedContent = content ?? buildNarrationContent();
  return JourneyEntry(
    id: id,
    place: SavedPlace(
      id: resolvedPlace.id,
      name: resolvedPlace.name,
      address: resolvedPlace.formattedAddress,
      imageUrl: resolvedPlace.primaryPhoto?.url,
    ),
    narrationContent: resolvedContent,
    narrationAspects: aspects,
    createdAt: createdAt ?? DateTime(2024, 1, 2, 10),
    language: language,
    tripId: tripId,
  );
}

/// Builds a [QuickGuideEntry] with sensible defaults.
QuickGuideEntry buildQuickGuideEntry({
  String id = 'quick-guide-1',
  Uint8List? imageBytes,
  String aiDescription = 'A short description from fake AI.',
  DateTime? createdAt,
  Language language = Language.english,
  String? tripId,
}) {
  return QuickGuideEntry(
    id: id,
    imageBytes: imageBytes ?? Uint8List.fromList(const [0, 1, 2, 3]),
    aiDescription: aiDescription,
    createdAt: createdAt ?? DateTime(2024, 1, 1, 12),
    language: language,
    tripId: tripId,
  );
}
