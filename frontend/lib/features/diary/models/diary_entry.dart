import 'package:flutter/foundation.dart';

/// 日記資料模型
@immutable
class DiaryEntry {
  /// 日記 ID
  final String id;

  /// 使用者 ID
  final String userId;

  /// 內容
  final String? content;

  /// AI-generated content
  final String? aiContent;

  /// Google Place ID
  final String? placeId;

  /// 地點名稱
  final String? placeName;

  /// 地點地址
  final String? placeAddress;

  /// 緯度
  final double? latitude;

  /// 經度
  final double? longitude;

  /// 造訪日期時間(精確到分鐘)
  final DateTime visitDate;

  /// 標籤列表
  final List<String> tags;

  /// 圖片路徑列表
  final List<String> imagePaths;

  /// 建立時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const DiaryEntry({
    required this.id,
    required this.userId,
    this.content,
    this.aiContent,
    this.placeId,
    this.placeName,
    this.placeAddress,
    this.latitude,
    this.longitude,
    required this.visitDate,
    this.tags = const [],
    this.imagePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 JSON 建立 DiaryEntry
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      aiContent: json['ai_content'] as String?,
      placeId: json['place_id'] as String?,
      placeName: json['place_name'] as String?,
      placeAddress: json['place_address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      visitDate: DateTime.parse(json['visit_date'] as String),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag as String)
              .toList() ??
          const [],
      imagePaths:
          (json['image_paths'] as List<dynamic>?)
              ?.map((path) => path as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'ai_content': aiContent,
      'place_id': placeId,
      'place_name': placeName,
      'place_address': placeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'visit_date': visitDate.toIso8601String(), // 完整的日期時間
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 建立副本,允許部分欄位更新
  DiaryEntry copyWith({
    String? id,
    String? userId,
    String? content,
    String? aiContent,
    String? placeId,
    String? placeName,
    String? placeAddress,
    double? latitude,
    double? longitude,
    DateTime? visitDate,
    List<String>? tags,
    List<String>? imagePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      aiContent: aiContent ?? this.aiContent,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visitDate: visitDate ?? this.visitDate,
      tags: tags ?? this.tags,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiaryEntry &&
        other.id == id &&
        other.userId == userId &&
        other.content == content &&
        other.aiContent == aiContent &&
        other.placeId == placeId &&
        other.placeName == placeName &&
        other.placeAddress == placeAddress &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.visitDate == visitDate &&
        listEquals(other.tags, tags) &&
        listEquals(other.imagePaths, imagePaths) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      content,
      aiContent,
      placeId,
      placeName,
      placeAddress,
      latitude,
      longitude,
      visitDate,
      Object.hashAll(tags),
      Object.hashAll(imagePaths),
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'DiaryEntry(id: $id, visitDate: $visitDate, '
        'placeName: $placeName, tags: $tags)';
  }
}
