import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class JourneyEntry {
  final String id;
  final SavedPlace place;
  final NarrationContent narrationContent;
  final Set<NarrationAspect> narrationAspects;
  final DateTime createdAt;
  final Language language;

  /// 所屬旅程的 id，`null` 代表尚未歸類（會顯示在「未分類」）。
  final String? tripId;

  const JourneyEntry({
    required this.id,
    required this.place,
    required this.narrationContent,
    required this.narrationAspects,
    required this.createdAt,
    required this.language,
    this.tripId,
  });

  /// 建立新的旅程記錄
  ///
  /// [id] 由呼叫端產生（例如 UUID），domain 層不負責 ID 生成策略。
  /// [tripId] 若提供則表示條目歸屬於該 Trip。
  factory JourneyEntry.create({
    required String id,
    required Place place,
    required Set<NarrationAspect> aspects,
    required NarrationContent content,
    required Language language,
    String? tripId,
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
      narrationAspects: aspects,
      createdAt: DateTime.now(),
      language: language,
      tripId: tripId,
    );
  }

  /// 回傳套用了新 [tripId] 後的副本（`null` 代表移回未分類）。
  JourneyEntry copyWithTripId(String? tripId) => JourneyEntry(
    id: id,
    place: place,
    narrationContent: narrationContent,
    narrationAspects: narrationAspects,
    createdAt: createdAt,
    language: language,
    tripId: tripId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': place.id,
    'place_name': place.name,
    'place_address': place.address,
    'place_image_url': place.imageUrl,
    'narration_text': narrationContent.text,
    'narration_styles': narrationAspects.map((a) => a.key).toList(),
    'created_at': createdAt.toIso8601String(),
    'language': language.code,
    'trip_id': tripId,
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

    // 向下相容：支援舊的 narration_style（單一字串）
    // 和新的 narration_styles（字串陣列）
    Set<NarrationAspect> narrationAspects;
    if (json.containsKey('narration_styles')) {
      final styles = (json['narration_styles'] as List<dynamic>).cast<String>();
      narrationAspects = styles
          .map((key) => NarrationAspect.fromKey(key))
          .whereType<NarrationAspect>()
          .toSet();
      if (narrationAspects.isEmpty) {
        narrationAspects = {NarrationAspect.historicalBackground};
      }
    } else {
      final aspect =
          NarrationAspect.fromKey(json['narration_style'] as String) ??
          NarrationAspect.historicalBackground;
      narrationAspects = {aspect};
    }

    return JourneyEntry(
      id: json['id'] as String,
      place: place,
      narrationContent: narrationContent,
      narrationAspects: narrationAspects,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: language,
      tripId: json['trip_id'] as String?,
    );
  }
}
