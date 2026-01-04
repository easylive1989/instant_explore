import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/data/mappers/narration_aspect_mapper.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// JourneyEntry 的資料轉換器
///
/// 負責在資料庫的扁平結構與領域模型之間進行轉換
class JourneyEntryMapper {
  /// 從資料庫的扁平結構解析為 JourneyEntry
  static JourneyEntry fromJson(Map<String, dynamic> json) {
    final languageStr = json['language'] as String? ?? 'zh-TW';
    final language = Language(languageStr);

    // 從扁平欄位建立 SavedPlace
    final place = SavedPlace(
      id: json['place_id'] as String,
      name: json['place_name'] as String,
      address: json['place_address'] as String,
      imageUrl: json['place_image_url'] as String?,
    );

    // 從扁平欄位建立 NarrationContent
    final narrationText = json['narration_text'] as String;
    final narrationContent = NarrationContent.create(
      narrationText,
      language: language,
    );

    // 解析 narration_style
    final narrationStyleStr = json['narration_style'] as String;
    final narrationAspect =
        NarrationAspectMapper.fromString(narrationStyleStr) ??
        NarrationAspect.historicalBackground;

    return JourneyEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      place: place,
      narrationContent: narrationContent,
      narrationAspect: narrationAspect,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: language,
    );
  }

  /// 轉換為資料庫的扁平結構
  static Map<String, dynamic> toJson(JourneyEntry entry) {
    return {
      'id': entry.id,
      'user_id': entry.userId,
      'place_id': entry.place.id,
      'place_name': entry.place.name,
      'place_address': entry.place.address,
      'place_image_url': entry.place.imageUrl,
      'narration_text': entry.narrationContent.text,
      'narration_style': NarrationAspectMapper.toApiString(
        entry.narrationAspect,
      ),
      'created_at': entry.createdAt.toIso8601String(),
      'language': entry.language.toString(),
    };
  }
}
