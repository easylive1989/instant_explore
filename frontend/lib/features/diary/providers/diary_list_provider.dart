import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/models/diary_tag.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';

/// 日記列表畫面狀態
class DiaryListState {
  final List<DiaryEntry> entries;
  final List<DiaryTag> allTags;
  final List<String> selectedTagIds;
  final bool isLoading;
  final String? error;

  const DiaryListState({
    this.entries = const [],
    this.allTags = const [],
    this.selectedTagIds = const [],
    this.isLoading = false,
    this.error,
  });

  DiaryListState copyWith({
    List<DiaryEntry>? entries,
    List<DiaryTag>? allTags,
    List<String>? selectedTagIds,
    bool? isLoading,
    String? error,
  }) {
    return DiaryListState(
      entries: entries ?? this.entries,
      allTags: allTags ?? this.allTags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 日記列表狀態管理器
class DiaryListNotifier extends StateNotifier<DiaryListState> {
  final DiaryRepository _repository;

  DiaryListNotifier(this._repository) : super(const DiaryListState()) {
    loadDiaries();
  }

  /// 載入日記列表
  Future<void> loadDiaries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = state.selectedTagIds.isEmpty
          ? await _repository.getAllDiaryEntries()
          : await _repository.getDiaryEntriesByTags(state.selectedTagIds);

      final tags = await _repository.getAllTags();

      state = state.copyWith(entries: entries, allTags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 切換標籤篩選
  void toggleTagFilter(String tagId) {
    final selectedTags = List<String>.from(state.selectedTagIds);

    if (selectedTags.contains(tagId)) {
      selectedTags.remove(tagId);
    } else {
      selectedTags.add(tagId);
    }

    state = state.copyWith(selectedTagIds: selectedTags);
    loadDiaries();
  }

  /// 清除所有標籤篩選
  void clearTagFilters() {
    state = state.copyWith(selectedTagIds: []);
    loadDiaries();
  }

  /// 刪除日記
  Future<void> deleteDiary(String diaryId) async {
    try {
      await _repository.deleteDiaryEntry(diaryId);
      await loadDiaries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Repository Provider（待 Task 1.2 建立）
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

/// 日記列表 Provider
final diaryListProvider =
    StateNotifierProvider<DiaryListNotifier, DiaryListState>(
      (ref) => DiaryListNotifier(ref.read(diaryRepositoryProvider)),
    );
