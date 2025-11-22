import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_diary/features/diary/models/diary_tag.dart';
import 'package:travel_diary/features/tags/models/tag.dart';
import 'package:travel_diary/features/tags/services/tag_repository.dart';

/// 標籤資料存取實作（使用 Supabase）
class TagRepositoryImpl implements TagRepository {
  final SupabaseClient _supabase;

  TagRepositoryImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<Tag>> getAllUserTags() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('使用者未登入');
      }

      final response = await _supabase
          .from('diary_tags')
          .select()
          .eq('user_id', userId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => DiaryTag.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('載入標籤失敗: $e');
    }
  }

  @override
  Future<Tag> createTag(String tagName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('使用者未登入');
      }

      final trimmedName = tagName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('標籤名稱不能為空');
      }

      // 嘗試建立標籤
      try {
        final response = await _supabase
            .from('diary_tags')
            .insert({'user_id': userId, 'name': trimmedName})
            .select()
            .single();

        return DiaryTag.fromJson(response);
      } catch (e) {
        // 如果是重複錯誤，查詢並返回現有標籤
        if (e.toString().contains('duplicate') ||
            e.toString().contains('unique')) {
          final existing = await _supabase
              .from('diary_tags')
              .select()
              .eq('user_id', userId)
              .eq('name', trimmedName)
              .single();

          return DiaryTag.fromJson(existing);
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('建立標籤失敗: $e');
    }
  }

  @override
  Future<void> deleteTag(String tagId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('使用者未登入');
      }

      // 先檢查標籤是否被使用
      final usageCount = await getTagUsageCount(tagId);
      if (usageCount > 0) {
        throw Exception('此標籤已被 $usageCount 篇日記使用，無法刪除');
      }

      await _supabase
          .from('diary_tags')
          .delete()
          .eq('id', tagId)
          .eq('user_id', userId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('刪除標籤失敗: $e');
    }
  }

  @override
  Future<int> getTagUsageCount(String tagId) async {
    try {
      final response = await _supabase
          .from('diary_entry_tags')
          .select('diary_entry_id')
          .eq('tag_id', tagId);

      return (response as List).length;
    } catch (e) {
      throw Exception('查詢標籤使用次數失敗: $e');
    }
  }
}
