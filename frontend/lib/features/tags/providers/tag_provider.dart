import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/tags/models/tag.dart';
import 'package:travel_diary/features/tags/services/tag_repository.dart';
import 'package:travel_diary/features/tags/services/tag_repository_impl.dart';

/// Tag Repository Provider
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepositoryImpl();
});

/// 標籤狀態
@immutable
class TagState {
  final List<Tag> tags;
  final bool isLoading;
  final String? error;

  const TagState({this.tags = const [], this.isLoading = false, this.error});

  TagState copyWith({List<Tag>? tags, bool? isLoading, String? error}) {
    return TagState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 標籤狀態管理 Notifier
class TagNotifier extends StateNotifier<TagState> {
  final TagRepository _repository;

  TagNotifier(this._repository) : super(const TagState()) {
    loadTags();
  }

  /// 載入所有標籤
  Future<void> loadTags() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tags = await _repository.getAllUserTags();
      state = state.copyWith(tags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 建立新標籤
  Future<Tag?> createTag(String name) async {
    try {
      final tag = await _repository.createTag(name);

      // 重新載入標籤列表
      await loadTags();

      return tag;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 刪除標籤
  Future<bool> deleteTag(String tagId) async {
    try {
      await _repository.deleteTag(tagId);

      // 重新載入標籤列表
      await loadTags();

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 取得標籤使用次數
  Future<int> getTagUsageCount(String tagId) async {
    try {
      return await _repository.getTagUsageCount(tagId);
    } catch (e) {
      return 0;
    }
  }

  /// 清除錯誤訊息
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 標籤狀態管理 Provider
final tagNotifierProvider = StateNotifierProvider<TagNotifier, TagState>((ref) {
  return TagNotifier(ref.read(tagRepositoryProvider));
});
