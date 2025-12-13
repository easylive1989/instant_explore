import 'package:context_app/features/player/models/narration_style.dart';

class PassportEntry {
  final String id;
  final String userId;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final String? placeImageUrl;
  final String narrationText;
  final NarrationStyle narrationStyle;
  final DateTime createdAt;

  const PassportEntry({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    this.placeImageUrl,
    required this.narrationText,
    required this.narrationStyle,
    required this.createdAt,
  });

  factory PassportEntry.fromJson(Map<String, dynamic> json) {
    return PassportEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      placeName: json['place_name'] as String,
      placeAddress: json['place_address'] as String,
      placeImageUrl: json['place_image_url'] as String?,
      narrationText: json['narration_text'] as String,
      narrationStyle: NarrationStyle.values.firstWhere(
        (e) => e.name == json['narration_style'],
        orElse: () => NarrationStyle.brief,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'narration_style': narrationStyle.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
