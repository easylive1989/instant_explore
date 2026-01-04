import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

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
}
