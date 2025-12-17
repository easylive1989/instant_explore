import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';

/// 導覽聚合根
///
/// 代表一次完整的語音導覽內容
/// 遵循 DDD 聚合根原則，只包含領域相關的資料
/// 播放狀態由 Presentation 層的 PlayerState 管理
class Narration {
  /// 唯一識別碼
  final String id;

  /// 地點資訊
  final Place place;

  /// 導覽介紹面向
  final NarrationAspect aspect;

  /// 導覽內容（生成後必定存在）
  final NarrationContent content;

  const Narration({
    required this.id,
    required this.place,
    required this.aspect,
    required this.content,
  });

  /// 建立副本並更新指定屬性
  Narration copyWith({
    String? id,
    Place? place,
    NarrationAspect? aspect,
    NarrationContent? content,
  }) {
    return Narration(
      id: id ?? this.id,
      place: place ?? this.place,
      aspect: aspect ?? this.aspect,
      content: content ?? this.content,
    );
  }

  @override
  String toString() {
    return 'Narration(id: $id, place: ${place.name}, aspect: $aspect)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Narration &&
        other.id == id &&
        other.place == place &&
        other.aspect == aspect &&
        other.content == content;
  }

  @override
  int get hashCode {
    return Object.hash(id, place, aspect, content);
  }
}
