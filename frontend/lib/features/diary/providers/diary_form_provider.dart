import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

/// 日記表單狀態
@immutable
class DiaryFormState {
  final String title;
  final QuillController contentController;
  final DateTime visitDate;
  final List<String> selectedTagIds;
  final List<File> selectedImages;
  final String? placeId;
  final String? placeName;
  final String? placeAddress;
  final double? latitude;
  final double? longitude;

  DiaryFormState({
    this.title = '',
    required this.contentController,
    DateTime? visitDate,
    this.selectedTagIds = const [],
    this.selectedImages = const [],
    this.placeId,
    this.placeName,
    this.placeAddress,
    this.latitude,
    this.longitude,
  }) : visitDate = visitDate ?? DateTime.now();

  DiaryFormState copyWith({
    String? title,
    QuillController? contentController,
    DateTime? visitDate,
    List<String>? selectedTagIds,
    List<File>? selectedImages,
    String? Function()? placeId,
    String? Function()? placeName,
    String? Function()? placeAddress,
    double? Function()? latitude,
    double? Function()? longitude,
  }) {
    return DiaryFormState(
      title: title ?? this.title,
      contentController: contentController ?? this.contentController,
      visitDate: visitDate ?? this.visitDate,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      selectedImages: selectedImages ?? this.selectedImages,
      placeId: placeId != null ? placeId() : this.placeId,
      placeName: placeName != null ? placeName() : this.placeName,
      placeAddress: placeAddress != null ? placeAddress() : this.placeAddress,
      latitude: latitude != null ? latitude() : this.latitude,
      longitude: longitude != null ? longitude() : this.longitude,
    );
  }
}

/// 日記表單 Notifier
class DiaryFormNotifier extends StateNotifier<DiaryFormState> {
  DiaryFormNotifier()
    : super(
        DiaryFormState(
          contentController: QuillController.basic(),
          visitDate: DateTime.now(),
        ),
      );

  @override
  void dispose() {
    state.contentController.dispose();
    super.dispose();
  }

  /// 更新標題
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// 更新內容 Controller
  void updateContentController(QuillController controller) {
    state = state.copyWith(contentController: controller);
  }

  /// 更新拜訪日期時間
  void updateVisitDate(DateTime date) {
    state = state.copyWith(visitDate: date);
  }

  /// 更新選中的標籤
  void updateTags(List<String> tagIds) {
    state = state.copyWith(selectedTagIds: tagIds);
  }

  /// 添加圖片
  void addImages(List<File> images) {
    final newImages = [...state.selectedImages, ...images];
    state = state.copyWith(selectedImages: newImages);
  }

  /// 移除圖片
  void removeImage(int index) {
    final newImages = List<File>.from(state.selectedImages);
    newImages.removeAt(index);
    state = state.copyWith(selectedImages: newImages);
  }

  /// 更新地點資訊
  void updatePlace({
    required String? placeId,
    required String? placeName,
    required String? placeAddress,
    required double? latitude,
    required double? longitude,
  }) {
    state = state.copyWith(
      placeId: () => placeId,
      placeName: () => placeName,
      placeAddress: () => placeAddress,
      latitude: () => latitude,
      longitude: () => longitude,
    );
  }

  /// 從現有日記載入資料
  void loadFromEntry(DiaryEntry entry) async {
    // 載入 Quill 內容
    if (entry.content != null && entry.content!.isNotEmpty) {
      final deltaJson = jsonDecode(entry.content!);
      final document = Document.fromJson(deltaJson);
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );

      state = state.copyWith(
        title: entry.title,
        contentController: controller,
        visitDate: entry.visitDate,
        placeId: () => entry.placeId,
        placeName: () => entry.placeName,
        placeAddress: () => entry.placeAddress,
        latitude: () => entry.latitude,
        longitude: () => entry.longitude,
      );
    } else {
      state = state.copyWith(
        title: entry.title,
        visitDate: entry.visitDate,
        placeId: () => entry.placeId,
        placeName: () => entry.placeName,
        placeAddress: () => entry.placeAddress,
        latitude: () => entry.latitude,
        longitude: () => entry.longitude,
      );
    }
  }

  /// 重置表單
  void reset() {
    state.contentController.dispose();
    state = DiaryFormState(
      contentController: QuillController.basic(),
      visitDate: DateTime.now(),
    );
  }
}

/// 日記表單 Provider
final diaryFormProvider =
    StateNotifierProvider.autoDispose<DiaryFormNotifier, DiaryFormState>(
      (ref) => DiaryFormNotifier(),
    );
