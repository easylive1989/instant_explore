import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class JourneyEntry {
  final String id;
  final SavedPlace place;
  final NarrationContent narrationContent;
  final NarrationAspect narrationAspect;
  final DateTime createdAt;
  final Language language;

  const JourneyEntry({
    required this.id,
    required this.place,
    required this.narrationContent,
    required this.narrationAspect,
    required this.createdAt,
    required this.language,
  });

  /// 建立新的旅程記錄
  ///
  /// [id] 由呼叫端產生（例如 UUID），domain 層不負責 ID 生成策略。
  factory JourneyEntry.create({
    required String id,
    required Place place,
    required NarrationAspect aspect,
    required NarrationContent content,
    required Language language,
  }) {
    final String? imageUrl = place.primaryPhoto?.url;

    final savedPlace = SavedPlace(
      id: place.id,
      name: place.name,
      address: place.formattedAddress,
      imageUrl: imageUrl,
    );

    return JourneyEntry(
      id: id,
      place: savedPlace,
      narrationContent: content,
      narrationAspect: aspect,
      createdAt: DateTime.now(),
      language: language,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': place.id,
    'place_name': place.name,
    'place_address': place.address,
    'place_image_url': place.imageUrl,
    'narration_text': narrationContent.text,
    'narration_style': narrationAspect.key,
    'created_at': createdAt.toIso8601String(),
    'language': language.code,
  };

  factory JourneyEntry.fromJson(Map<String, dynamic> json) {
    final languageStr = json['language'] as String? ?? 'zh-TW';
    final language = Language(languageStr);

    final place = SavedPlace(
      id: json['place_id'] as String,
      name: json['place_name'] as String,
      address: json['place_address'] as String,
      imageUrl: json['place_image_url'] as String?,
    );

    final narrationContent = NarrationContent.create(
      json['narration_text'] as String,
      language: language,
    );

    final narrationAspect =
        NarrationAspect.fromKey(json['narration_style'] as String) ??
        NarrationAspect.historicalBackground;

    return JourneyEntry(
      id: json['id'] as String,
      place: place,
      narrationContent: narrationContent,
      narrationAspect: narrationAspect,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: language,
    );
  }
}
