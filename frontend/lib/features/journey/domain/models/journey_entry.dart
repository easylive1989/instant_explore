import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/core/domain/models/language.dart';

class JourneyEntry {
  final String id;
  final String userId;
  final SavedPlace place;
  final NarrationContent narrationContent;
  final DateTime createdAt;
  final Language language;

  const JourneyEntry({
    required this.id,
    required this.userId,
    required this.place,
    required this.narrationContent,
    required this.createdAt,
    required this.language,
  });

  factory JourneyEntry.fromJson(Map<String, dynamic> json) {
    return JourneyEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      place: SavedPlace.fromJson(json['place'] as Map<String, dynamic>),
      narrationContent: NarrationContent.fromJson(
        json['narration_content'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      language: Language.fromString(json['language'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'place': place.toJson(),
      'narration_content': narrationContent.toJson(),
      'created_at': createdAt.toIso8601String(),
      'language': language.toString(),
    };
  }
}
