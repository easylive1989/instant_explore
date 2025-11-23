import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/models/diary_tag.dart';
import 'package:travel_diary/features/diary/models/diary_image.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';

/// Supabase 實作的日記資料存取層
class DiaryRepositoryImpl implements DiaryRepository {
  final SupabaseClient _supabase;

  DiaryRepositoryImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ==================== 日記 CRUD 操作 ====================

  @override
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 使用 JOIN 一次性查詢所有資料（解決 N+1 查詢問題）
    final response = await _supabase
        .from('diary_entries')
        .select('''
          *,
          diary_entry_tags(tag_id, diary_tags(id, name)),
          diary_images(storage_path, display_order)
        ''')
        .eq('user_id', userId)
        .order('visit_date', ascending: false);

    final entries = (response as List).map((json) {
      final data = json as Map<String, dynamic>;

      // 提取標籤
      final tags =
          (data['diary_entry_tags'] as List?)
              ?.map((tagData) {
                final tag = tagData['diary_tags'];
                return tag != null ? tag['name'] as String : null;
              })
              .whereType<String>()
              .toList() ??
          [];

      // 提取圖片路徑（按 display_order 排序）
      final imagesList = (data['diary_images'] as List?) ?? [];
      imagesList.sort(
        (a, b) =>
            (a['display_order'] as int).compareTo(b['display_order'] as int),
      );
      final imagePaths = imagesList
          .map((img) => img['storage_path'] as String)
          .toList();

      // 移除關聯資料，避免 DiaryEntry.fromJson 解析錯誤
      data.remove('diary_entry_tags');
      data.remove('diary_images');

      return DiaryEntry.fromJson(
        data,
      ).copyWith(tags: tags, imagePaths: imagePaths);
    }).toList();

    return entries;
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntriesByTags(List<String> tagIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (tagIds.isEmpty) {
      return getAllDiaryEntries();
    }

    // 查詢有指定標籤的日記 ID
    final response = await _supabase
        .from('diary_entry_tags')
        .select('diary_entry_id')
        .inFilter('tag_id', tagIds);

    final diaryIds = (response as List)
        .map((e) => e['diary_entry_id'] as String)
        .toSet();

    if (diaryIds.isEmpty) return [];

    // 使用 JOIN 一次性查詢所有資料（解決 N+1 查詢問題）
    final entriesResponse = await _supabase
        .from('diary_entries')
        .select('''
          *,
          diary_entry_tags(tag_id, diary_tags(id, name)),
          diary_images(storage_path, display_order)
        ''')
        .inFilter('id', diaryIds.toList())
        .eq('user_id', userId)
        .order('visit_date', ascending: false);

    final entries = (entriesResponse as List).map((json) {
      final data = json as Map<String, dynamic>;

      // 提取標籤
      final tags =
          (data['diary_entry_tags'] as List?)
              ?.map((tagData) {
                final tag = tagData['diary_tags'];
                return tag != null ? tag['name'] as String : null;
              })
              .whereType<String>()
              .toList() ??
          [];

      // 提取圖片路徑（按 display_order 排序）
      final imagesList = (data['diary_images'] as List?) ?? [];
      imagesList.sort(
        (a, b) =>
            (a['display_order'] as int).compareTo(b['display_order'] as int),
      );
      final imagePaths = imagesList
          .map((img) => img['storage_path'] as String)
          .toList();

      // 移除關聯資料，避免 DiaryEntry.fromJson 解析錯誤
      data.remove('diary_entry_tags');
      data.remove('diary_images');

      return DiaryEntry.fromJson(
        data,
      ).copyWith(tags: tags, imagePaths: imagePaths);
    }).toList();

    return entries;
  }

  @override
  Future<DiaryEntry?> getDiaryEntryById(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('diary_entries')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    final entry = DiaryEntry.fromJson(response);

    // 載入標籤和圖片
    final tags = await getTagsForDiary(entry.id);
    final images = await getImagesForDiary(entry.id);

    return entry.copyWith(
      tags: tags.map((tag) => tag.name).toList(),
      imagePaths: images.map((img) => img.storagePath).toList(),
    );
  }

  @override
  Future<DiaryEntry> createDiaryEntry(DiaryEntry entry) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final entryData = entry.toJson();
    entryData['user_id'] = userId;

    // 移除 id 欄位，讓資料庫自動生成 UUID
    entryData.remove('id');
    // 移除時間戳記欄位，讓資料庫使用預設值
    entryData.remove('created_at');
    entryData.remove('updated_at');

    final response = await _supabase
        .from('diary_entries')
        .insert(entryData)
        .select()
        .single();

    return DiaryEntry.fromJson(response);
  }

  @override
  Future<DiaryEntry> updateDiaryEntry(DiaryEntry entry) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('diary_entries')
        .update(entry.toJson())
        .eq('id', entry.id)
        .eq('user_id', userId)
        .select()
        .single();

    return DiaryEntry.fromJson(response);
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('diary_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ==================== 標籤操作 ====================

  @override
  Future<List<DiaryTag>> getAllTags() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('diary_tags')
        .select()
        .eq('user_id', userId)
        .order('name');

    return (response as List)
        .map((json) => DiaryTag.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DiaryTag> createTag(String tagName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('diary_tags')
          .insert({'user_id': userId, 'name': tagName})
          .select()
          .single();

      return DiaryTag.fromJson(response);
    } catch (e) {
      // 如果標籤已存在,查詢並返回現有標籤
      final existing = await _supabase
          .from('diary_tags')
          .select()
          .eq('user_id', userId)
          .eq('name', tagName)
          .single();

      return DiaryTag.fromJson(existing);
    }
  }

  @override
  Future<void> deleteTag(String tagId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('diary_tags')
        .delete()
        .eq('id', tagId)
        .eq('user_id', userId);
  }

  @override
  Future<void> addTagToDiary(String diaryId, String tagId) async {
    await _supabase.from('diary_entry_tags').insert({
      'diary_entry_id': diaryId,
      'tag_id': tagId,
    });
  }

  @override
  Future<void> removeTagFromDiary(String diaryId, String tagId) async {
    await _supabase
        .from('diary_entry_tags')
        .delete()
        .eq('diary_entry_id', diaryId)
        .eq('tag_id', tagId);
  }

  @override
  Future<void> removeAllTagsFromDiary(String diaryId) async {
    await _supabase
        .from('diary_entry_tags')
        .delete()
        .eq('diary_entry_id', diaryId);
  }

  @override
  Future<List<DiaryTag>> getTagsForDiary(String diaryId) async {
    final response = await _supabase
        .from('diary_entry_tags')
        .select('tag_id, diary_tags(*)')
        .eq('diary_entry_id', diaryId);

    return (response as List)
        .map(
          (item) =>
              DiaryTag.fromJson(item['diary_tags'] as Map<String, dynamic>),
        )
        .toList();
  }

  // ==================== 圖片操作 ====================

  @override
  Future<List<DiaryImage>> getImagesForDiary(String diaryId) async {
    final response = await _supabase
        .from('diary_images')
        .select()
        .eq('diary_entry_id', diaryId)
        .order('display_order');

    return (response as List)
        .map((json) => DiaryImage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DiaryImage> addImageToDiary({
    required String diaryId,
    required String storagePath,
    required int displayOrder,
  }) async {
    final response = await _supabase
        .from('diary_images')
        .insert({
          'diary_entry_id': diaryId,
          'storage_path': storagePath,
          'display_order': displayOrder,
        })
        .select()
        .single();

    return DiaryImage.fromJson(response);
  }

  @override
  Future<void> deleteImage(String imageId) async {
    await _supabase.from('diary_images').delete().eq('id', imageId);
  }

  @override
  Future<void> updateImageOrder(String imageId, int newOrder) async {
    await _supabase
        .from('diary_images')
        .update({'display_order': newOrder})
        .eq('id', imageId);
  }
}
