import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

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

  /// 從資料庫的扁平結構解析
  factory JourneyEntry.fromJson(Map<String, dynamic> json) {
    final languageStr = json['language'] as String? ?? 'zh-TW';

    // 從扁平欄位建立 SavedPlace
    final place = SavedPlace(
      id: json['place_id'] as String,
      name: json['place_name'] as String,
      address: json['place_address'] as String,
      imageUrl: json['place_image_url'] as String?,
    );

    // 從扁平欄位建立 NarrationContent
    final narrationText = json['narration_text'] as String;
    final narrationContent = NarrationContent.fromText(
      narrationText,
      language: languageStr,
    );

    return JourneyEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      place: place,
      narrationContent: narrationContent,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: Language.fromString(languageStr),
    );
  }

  /// 轉換為資料庫的扁平結構
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'place_id': place.id,
      'place_name': place.name,
      'place_address': place.address,
      'place_image_url': place.imageUrl,
      'narration_text': narrationContent.text,
      'created_at': createdAt.toIso8601String(),
      'language': language.toString(),
    };
  }
}
