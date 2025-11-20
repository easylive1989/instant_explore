import 'package:flutter/foundation.dart';

/// 日記標籤資料模型
@immutable
class DiaryTag {
  /// 標籤 ID
  final String id;

  /// 使用者 ID
  final String userId;

  /// 標籤名稱
  final String name;

  /// 建立時間
  final DateTime createdAt;

  const DiaryTag({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  /// 從 JSON 建立 DiaryTag
  factory DiaryTag.fromJson(Map<String, dynamic> json) {
    return DiaryTag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 建立副本,允許部分欄位更新
  DiaryTag copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
  }) {
    return DiaryTag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiaryTag &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, name, createdAt);
  }

  @override
  String toString() {
    return 'DiaryTag(id: $id, name: $name)';
  }
}
