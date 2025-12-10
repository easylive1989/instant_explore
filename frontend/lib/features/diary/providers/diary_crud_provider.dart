import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'package:travel_diary/features/images/providers/image_providers.dart';

/// 日記 CRUD 狀態
@immutable
class DiaryCrudState {
  final bool isLoading;
  final String? error;
  final DiaryEntry? savedEntry;

  const DiaryCrudState({this.isLoading = false, this.error, this.savedEntry});

  DiaryCrudState copyWith({
    bool? isLoading,
    String? error,
    DiaryEntry? savedEntry,
  }) {
    return DiaryCrudState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      savedEntry: savedEntry ?? this.savedEntry,
    );
  }
}

/// 日記 CRUD Notifier
class DiaryCrudNotifier extends StateNotifier<DiaryCrudState> {
  final DiaryRepository _repository;
  final ImageUploadService _imageUploadService;

  DiaryCrudNotifier(this._repository, this._imageUploadService)
    : super(const DiaryCrudState());

  /// 建立新日記(包含圖片上傳)
  Future<DiaryEntry?> createDiary({
    required String contentJson,
    String? aiContent,
    required DateTime visitDate,
    required List<String> tagIds,
    required List<File> images,
    String? placeId,
    String? placeName,
    String? placeAddress,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. 建立日記資料
      final diaryData = DiaryEntry(
        id: '',
        userId: '',
        content: contentJson,
        aiContent: aiContent,
        placeId: placeId,
        placeName: placeName,
        placeAddress: placeAddress,
        latitude: latitude,
        longitude: longitude,
        visitDate: visitDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedEntry = await _repository.createDiaryEntry(diaryData);

      // 2. 上傳圖片
      if (images.isNotEmpty) {
        final uploadedPaths = await _imageUploadService.uploadMultipleImages(
          imageFiles: images,
          diaryId: savedEntry.id,
        );

        // 3. 將圖片記錄到資料庫
        for (int i = 0; i < uploadedPaths.length; i++) {
          await _repository.addImageToDiary(
            diaryId: savedEntry.id,
            storagePath: uploadedPaths[i],
            displayOrder: i,
          );
        }
      }

      // 4. 處理標籤
      for (final tagId in tagIds) {
        await _repository.addTagToDiary(savedEntry.id, tagId);
      }

      state = state.copyWith(isLoading: false, savedEntry: savedEntry);
      return savedEntry;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '儲存失敗: $e');
      return null;
    }
  }

  /// 更新日記
  Future<DiaryEntry?> updateDiary({
    required String diaryId,
    required String userId,
    required String contentJson,
    String? aiContent,
    required DateTime visitDate,
    required List<String> tagIds,
    required List<File> newImages,
    String? placeId,
    String? placeName,
    String? placeAddress,
    double? latitude,
    double? longitude,
    required DateTime createdAt,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. 更新日記資料
      final diaryData = DiaryEntry(
        id: diaryId,
        userId: userId,
        content: contentJson,
        aiContent: aiContent,
        placeId: placeId,
        placeName: placeName,
        placeAddress: placeAddress,
        latitude: latitude,
        longitude: longitude,
        visitDate: visitDate,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      final savedEntry = await _repository.updateDiaryEntry(diaryData);

      // 2. 上傳新增的圖片
      if (newImages.isNotEmpty) {
        final uploadedPaths = await _imageUploadService.uploadMultipleImages(
          imageFiles: newImages,
          diaryId: savedEntry.id,
        );

        // 3. 將圖片記錄到資料庫
        for (int i = 0; i < uploadedPaths.length; i++) {
          await _repository.addImageToDiary(
            diaryId: savedEntry.id,
            storagePath: uploadedPaths[i],
            displayOrder: i,
          );
        }
      }

      // 4. 處理標籤(先刪除所有再重新添加)
      await _repository.removeAllTagsFromDiary(savedEntry.id);
      for (final tagId in tagIds) {
        await _repository.addTagToDiary(savedEntry.id, tagId);
      }

      state = state.copyWith(isLoading: false, savedEntry: savedEntry);
      return savedEntry;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '更新失敗: $e');
      return null;
    }
  }

  /// 刪除日記
  Future<bool> deleteDiary(String diaryId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deleteDiaryEntry(diaryId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '刪除失敗: $e');
      return false;
    }
  }

  /// 清除錯誤訊息
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 日記 CRUD Provider
final diaryCrudProvider =
    StateNotifierProvider<DiaryCrudNotifier, DiaryCrudState>((ref) {
      return DiaryCrudNotifier(
        ref.watch(diaryRepositoryProvider),
        ref.watch(imageUploadServiceProvider),
      );
    });
