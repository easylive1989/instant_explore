import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/models/diary_tag.dart';
import 'package:travel_diary/features/diary/models/diary_image.dart';

/// 日記資料存取層介面
abstract class DiaryRepository {
  // ==================== 日記 CRUD 操作 ====================

  /// 取得使用者的所有日記 (依造訪日期排序,最新的在前)
  Future<List<DiaryEntry>> getAllDiaryEntries();

  /// 依標籤篩選日記
  Future<List<DiaryEntry>> getDiaryEntriesByTags(List<String> tagIds);

  /// 取得單筆日記詳情
  Future<DiaryEntry?> getDiaryEntryById(String id);

  /// 建立新日記
  Future<DiaryEntry> createDiaryEntry(DiaryEntry entry);

  /// 更新日記
  Future<DiaryEntry> updateDiaryEntry(DiaryEntry entry);

  /// 刪除日記
  Future<void> deleteDiaryEntry(String id);

  // ==================== 標籤操作 ====================

  /// 取得使用者的所有標籤
  Future<List<DiaryTag>> getAllTags();

  /// 建立新標籤
  Future<DiaryTag> createTag(String tagName);

  /// 刪除標籤
  Future<void> deleteTag(String tagId);

  /// 為日記新增標籤
  Future<void> addTagToDiary(String diaryId, String tagId);

  /// 從日記移除標籤
  Future<void> removeTagFromDiary(String diaryId, String tagId);

  /// 移除日記的所有標籤
  Future<void> removeAllTagsFromDiary(String diaryId);

  /// 取得日記的所有標籤
  Future<List<DiaryTag>> getTagsForDiary(String diaryId);

  // ==================== 圖片操作 ====================

  /// 取得日記的所有圖片
  Future<List<DiaryImage>> getImagesForDiary(String diaryId);

  /// 新增圖片記錄到日記
  Future<DiaryImage> addImageToDiary({
    required String diaryId,
    required String storagePath,
    required int displayOrder,
  });

  /// 刪除圖片記錄
  Future<void> deleteImage(String imageId);

  /// 更新圖片順序
  Future<void> updateImageOrder(String imageId, int newOrder);
}
