import 'package:travel_diary/features/tags/models/tag.dart';

/// 標籤資料存取介面
abstract class TagRepository {
  /// 取得目前使用者的所有標籤
  Future<List<Tag>> getAllUserTags();

  /// 建立新標籤
  ///
  /// [tagName] 標籤名稱
  /// 如果標籤已存在，返回現有標籤
  Future<Tag> createTag(String tagName);

  /// 刪除標籤
  ///
  /// [tagId] 標籤 ID
  /// 注意：刪除前應檢查標籤是否被使用
  Future<void> deleteTag(String tagId);

  /// 取得標籤的使用次數
  ///
  /// [tagId] 標籤 ID
  /// 返回有多少篇日記使用此標籤
  Future<int> getTagUsageCount(String tagId);
}
