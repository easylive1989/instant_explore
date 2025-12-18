import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

class JourneyEntry {
  final String id;
  final String userId;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final String? placeImageUrl;
  final String narrationText;
  final NarrationAspect narrationAspect;
  final DateTime createdAt;
  final String language; // 語言代碼 (例如: 'zh-TW', 'en-US')，必填

  const JourneyEntry({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    this.placeImageUrl,
    required this.narrationText,
    required this.narrationAspect,
    required this.createdAt,
    required this.language, // 必填參數
  });

  factory JourneyEntry.fromJson(Map<String, dynamic> json) {
    return JourneyEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String,
      placeAddress: json['place_address'] as String,
      placeImageUrl: json['place_image_url'] as String?,
      narrationText: json['narration_text'] as String,
      narrationAspect:
          NarrationAspect.fromString(json['narration_style'] as String) ??
          NarrationAspect.historicalBackground,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: json['language'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'place_id': placeId,
      'place_name': placeName,
      'place_address': placeAddress,
      'place_image_url': placeImageUrl,
      'narration_text': narrationText,
      'narration_style': narrationAspect.toApiString(),
      'created_at': createdAt.toIso8601String(),
      'language': language,
    };
  }
}
