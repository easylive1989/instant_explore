import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';

/// 日記詳情頁面的狀態
@immutable
class DiaryDetailState {
  final DiaryEntry entry;
  final bool isDeleting;
  final bool isLoading;
  final String? error;

  const DiaryDetailState({
    required this.entry,
    this.isDeleting = false,
    this.isLoading = false,
    this.error,
  });

  DiaryDetailState copyWith({
    DiaryEntry? entry,
    bool? isDeleting,
    bool? isLoading,
    String? error,
  }) {
    return DiaryDetailState(
      entry: entry ?? this.entry,
      isDeleting: isDeleting ?? this.isDeleting,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  DiaryDetailState clearError() {
    return copyWith(error: null);
  }
}

/// 日記詳情頁面的業務邏輯處理
class DiaryDetailNotifier extends StateNotifier<DiaryDetailState> {
  final DiaryRepository _repository;
  final ImageUploadService _imageUploadService;

  DiaryDetailNotifier(
    this._repository,
    this._imageUploadService,
    DiaryEntry initialEntry,
  ) : super(DiaryDetailState(entry: initialEntry));

  /// 刪除日記（包含圖片）
  Future<bool> deleteDiary() async {
    if (state.isDeleting) return false;

    state = state.copyWith(isDeleting: true, error: null);

    try {
      // 先刪除圖片
      if (state.entry.imagePaths.isNotEmpty) {
        await _imageUploadService.deleteMultipleImages(state.entry.imagePaths);
      }

      // 再刪除日記
      await _repository.deleteDiaryEntry(state.entry.id);

      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: '刪除失敗: $e');
      return false;
    }
  }

  /// 重新載入日記資料
  Future<void> reloadDiary() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedEntry = await _repository.getDiaryEntryById(state.entry.id);

      if (updatedEntry != null) {
        state = state.copyWith(entry: updatedEntry, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: '找不到日記資料');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '重新載入失敗: $e');
    }
  }

  /// 取得單一圖片的 URL
  String getImageUrl(String storagePath) {
    return _imageUploadService.getImageUrl(storagePath);
  }

  /// 取得所有圖片的 URL 列表
  List<String> getImageUrls() {
    return state.entry.imagePaths
        .map((path) => _imageUploadService.getImageUrl(path))
        .toList();
  }

  /// 清除錯誤訊息
  void clearError() {
    state = state.clearError();
  }
}

/// 日記詳情 Provider
///
/// 使用 family 傳入初始的 DiaryEntry
/// 使用 autoDispose 在頁面離開時自動清理資源
final diaryDetailProvider = StateNotifierProvider.autoDispose
    .family<DiaryDetailNotifier, DiaryDetailState, DiaryEntry>((ref, entry) {
      return DiaryDetailNotifier(
        ref.read(diaryRepositoryProvider),
        ref.read(imageUploadServiceProvider),
        entry,
      );
    });
