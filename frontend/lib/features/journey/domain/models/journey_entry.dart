import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:uuid/uuid.dart';

class JourneyEntry {
  final String id;
  final String userId;
  final SavedPlace place;
  final NarrationContent narrationContent;
  final NarrationAspect narrationAspect;
  final DateTime createdAt;
  final Language language;

  const JourneyEntry({
    required this.id,
    required this.userId,
    required this.place,
    required this.narrationContent,
    required this.narrationAspect,
    required this.createdAt,
    required this.language,
  });

  /// 建立新的旅程記錄
  factory JourneyEntry.create({
    required String userId,
    required Place place,
    required NarrationAspect aspect,
    required NarrationContent content,
    required Language language,
  }) {
    const uuid = Uuid();

    String? imageUrl;
    if (place.primaryPhoto != null) {
      imageUrl = place.primaryPhoto!.url;
    }

    final savedPlace = SavedPlace(
      id: place.id,
      name: place.name,
      address: place.formattedAddress,
      imageUrl: imageUrl,
    );

    return JourneyEntry(
      id: uuid.v4(),
      userId: userId,
      place: savedPlace,
      narrationContent: content,
      narrationAspect: aspect,
      createdAt: DateTime.now(),
      language: language,
    );
  }
}
