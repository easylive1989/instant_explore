import 'package:flutter/foundation.dart';

/// 日記圖片資料模型
@immutable
class DiaryImage {
  /// 圖片 ID
  final String id;

  /// 日記 ID
  final String diaryEntryId;

  /// 儲存路徑 (Supabase Storage 路徑)
  final String storagePath;

  /// 顯示順序
  final int displayOrder;

  /// 建立時間
  final DateTime createdAt;

  const DiaryImage({
    required this.id,
    required this.diaryEntryId,
    required this.storagePath,
    required this.displayOrder,
    required this.createdAt,
  });

  /// 從 JSON 建立 DiaryImage
  factory DiaryImage.fromJson(Map<String, dynamic> json) {
    return DiaryImage(
      id: json['id'] as String,
      diaryEntryId: json['diary_entry_id'] as String,
      storagePath: json['storage_path'] as String,
      displayOrder: json['display_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diary_entry_id': diaryEntryId,
      'storage_path': storagePath,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 建立副本,允許部分欄位更新
  DiaryImage copyWith({
    String? id,
    String? diaryEntryId,
    String? storagePath,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return DiaryImage(
      id: id ?? this.id,
      diaryEntryId: diaryEntryId ?? this.diaryEntryId,
      storagePath: storagePath ?? this.storagePath,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiaryImage &&
        other.id == id &&
        other.diaryEntryId == diaryEntryId &&
        other.storagePath == storagePath &&
        other.displayOrder == displayOrder &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, diaryEntryId, storagePath, displayOrder, createdAt);
  }

  @override
  String toString() {
    return 'DiaryImage(id: $id, storagePath: $storagePath, '
        'displayOrder: $displayOrder)';
  }
}
