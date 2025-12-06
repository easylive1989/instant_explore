import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/models/diary_entry_view_data.dart';
import 'package:travel_diary/features/diary/models/diary_tag.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'package:travel_diary/features/images/providers/image_providers.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

/// 日記列表畫面狀態
class DiaryListState {
  final List<DiaryEntryViewData> entries;
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
    List<DiaryEntryViewData>? entries,
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
  final ImageUploadService _imageUploadService;

  DiaryListNotifier(this._repository, this._imageUploadService)
    : super(const DiaryListState()) {
    loadDiaries();
  }

  /// 載入日記列表
  Future<void> loadDiaries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final diaryEntries = state.selectedTagIds.isEmpty
          ? await _repository.getAllDiaryEntries()
          : await _repository.getDiaryEntriesByTags(state.selectedTagIds);

      final tags = await _repository.getAllTags();

      final viewDataEntries = diaryEntries.map((entry) {
        final imageUrl = entry.imagePaths.isNotEmpty
            ? _imageUploadService.getImageUrl(entry.imagePaths.first)
            : null;
        return DiaryEntryViewData(
          id: entry.id,
          visitDate: entry.visitDate,
          placeName: entry.placeName,
          imageUrl: imageUrl,
        );
      }).toList();

      state = state.copyWith(
        entries: viewDataEntries,
        allTags: tags,
        isLoading: false,
      );
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
      // Note: Deleting images associated with the diary is not handled here.
      // This might be a separate concern, possibly handled via backend triggers
      // or a more complex deletion service. For now, we only delete the entry.
      await _repository.deleteDiaryEntry(diaryId);
      await loadDiaries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// 日記列表 Provider
final diaryListProvider =
    StateNotifierProvider<DiaryListNotifier, DiaryListState>(
      (ref) => DiaryListNotifier(
        ref.read(diaryRepositoryProvider),
        ref.read(imageUploadServiceProvider),
      ),
    );
