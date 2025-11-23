import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/features/places/screens/place_picker_screen.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/tags/widgets/tag_selector.dart';
import 'package:travel_diary/features/diary/widgets/rich_text_editor.dart';
import 'package:travel_diary/features/places/models/place.dart';
import 'package:travel_diary/features/diary/providers/diary_form_provider.dart';
import 'package:travel_diary/features/diary/providers/diary_crud_provider.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'dart:convert';

/// 日記新增/編輯畫面
class DiaryCreateScreen extends ConsumerStatefulWidget {
  final DiaryEntry? existingEntry;

  const DiaryCreateScreen({super.key, this.existingEntry});

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingEntry != null;

    // 延遲初始化,確保 provider 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadExistingEntry();
      }
    });
  }

  Future<void> _loadExistingEntry() async {
    final entry = widget.existingEntry!;

    // 使用 form provider 載入資料
    ref.read(diaryFormProvider.notifier).loadFromEntry(entry);

    // 載入標籤 ID
    try {
      final repository = ref.read(diaryRepositoryProvider);
      final diaryTags = await repository.getTagsForDiary(entry.id);
      ref
          .read(diaryFormProvider.notifier)
          .updateTags(diaryTags.map((tag) => tag.id).toList());
    } catch (e) {
      // 標籤載入失敗時使用空列表
    }
    // 注意:現有圖片不會載入到 selectedImages,因為它們已經在 Storage
  }

  Future<void> _pickImages() async {
    try {
      final formState = ref.read(diaryFormProvider);
      final imagePickerService = ref.read(imagePickerServiceProvider);

      final images = await imagePickerService.pickMultipleImagesFromGallery(
        maxImages: 5 - formState.selectedImages.length,
      );

      if (images.isNotEmpty) {
        ref.read(diaryFormProvider.notifier).addImages(images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('選擇圖片失敗: $e')));
      }
    }
  }

  void _removeImage(int index) {
    ref.read(diaryFormProvider.notifier).removeImage(index);
  }

  Future<void> _selectDateTime() async {
    final formState = ref.read(diaryFormProvider);
    DateTime tempPickedDate = formState.visitDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              // 頂部按鈕列
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        ref
                            .read(diaryFormProvider.notifier)
                            .updateVisitDate(tempPickedDate);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '確認',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue.resolveFrom(
                            context,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 日期時間選擇器
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: formState.visitDate,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime.now(),
                  use24hFormat: true,
                  onDateTimeChanged: (newDateTime) {
                    tempPickedDate = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectPlace() async {
    final selectedPlace = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (context) => const PlacePickerScreen()),
    );

    if (selectedPlace != null) {
      ref
          .read(diaryFormProvider.notifier)
          .updatePlace(
            placeId: selectedPlace.id,
            placeName: selectedPlace.name,
            placeAddress: selectedPlace.formattedAddress,
            latitude: selectedPlace.location.latitude,
            longitude: selectedPlace.location.longitude,
          );
    }
  }

  Future<void> _saveDiary() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(diaryFormProvider);

    if (formState.placeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇地點')));
      return;
    }

    // 將 Quill Delta 轉換為 JSON 字串
    final deltaJson = jsonEncode(
      formState.contentController.document.toDelta().toJson(),
    );

    DiaryEntry? savedEntry;

    if (_isEditing) {
      savedEntry = await ref
          .read(diaryCrudProvider.notifier)
          .updateDiary(
            diaryId: widget.existingEntry!.id,
            userId: widget.existingEntry!.userId,
            title: formState.title,
            contentJson: deltaJson,
            visitDate: formState.visitDate,
            tagIds: formState.selectedTagIds,
            newImages: formState.selectedImages,
            placeId: formState.placeId,
            placeName: formState.placeName,
            placeAddress: formState.placeAddress,
            latitude: formState.latitude,
            longitude: formState.longitude,
            createdAt: widget.existingEntry!.createdAt,
          );
    } else {
      savedEntry = await ref
          .read(diaryCrudProvider.notifier)
          .createDiary(
            title: formState.title,
            contentJson: deltaJson,
            visitDate: formState.visitDate,
            tagIds: formState.selectedTagIds,
            images: formState.selectedImages,
            placeId: formState.placeId,
            placeName: formState.placeName,
            placeAddress: formState.placeAddress,
            latitude: formState.latitude,
            longitude: formState.longitude,
          );
    }

    if (savedEntry != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_isEditing ? '日記已更新' : '日記已建立')));
      Navigator.of(context).pop(true); // 返回 true 表示已儲存
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(diaryFormProvider);
    final crudState = ref.watch(diaryCrudProvider);

    // 監聽 CRUD 狀態錯誤
    ref.listen<DiaryCrudState>(diaryCrudProvider, (previous, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編輯日記' : '新增日記'),
        actions: [
          if (crudState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveDiary, child: const Text('儲存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGroup1(formState),
            const SizedBox(height: 16),
            _buildGroup2(formState),
            const SizedBox(height: 16),
            _buildGroup3(formState),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Group 1: 標題內文與時間
  Widget _buildGroup1(DiaryFormState formState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          TextFormField(
            initialValue: formState.title,
            decoration: const InputDecoration(
              labelText: '標題',
              hintText: '今天去了哪裡?',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            onChanged: (value) {
              ref.read(diaryFormProvider.notifier).updateTitle(value);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入標題';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 內容(富文本編輯器)
          RichTextEditor(
            controller: formState.contentController,
            hintText: '分享你的心得與感想...',
            maxLength: 1000,
            height: 200,
          ),
          const SizedBox(height: 16),

          // 日期與時間
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat(
                        'yyyy-MM-dd HH:mm',
                      ).format(formState.visitDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Group 2: 地點與圖片混合顯示
  Widget _buildGroup2(DiaryFormState formState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('地點與照片', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildPlaceAndImageGrid(formState),
        ],
      ),
    );
  }

  /// Group 3: 標籤
  Widget _buildGroup3(DiaryFormState formState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: TagSelector(
        selectedTagIds: formState.selectedTagIds,
        onTagsChanged: (newTagIds) {
          ref.read(diaryFormProvider.notifier).updateTags(newTagIds);
        },
        maxTags: 10,
      ),
    );
  }

  /// 地點與圖片混合網格
  Widget _buildPlaceAndImageGrid(DiaryFormState formState) {
    const imageSize = 90.0;
    const spacing = 8.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        // 地點縮圖 (第一個位置)
        _buildPlaceThumbnail(formState, imageSize),
        // 圖片
        ...formState.selectedImages.asMap().entries.map(
          (entry) => _buildImageThumbnail(entry.value, entry.key, imageSize),
        ),
        // 添加圖片按鈕
        if (formState.selectedImages.length < 5)
          _buildAddImageButton(imageSize),
      ],
    );
  }

  /// 地點縮圖
  Widget _buildPlaceThumbnail(DiaryFormState formState, double size) {
    final hasPlace =
        formState.placeId != null &&
        formState.latitude != null &&
        formState.longitude != null;

    return GestureDetector(
      onTap: _selectPlace,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasPlace
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: hasPlace
            ? Stack(
                children: [
                  // 地點資訊卡片
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        if (formState.placeName != null)
                          Text(
                            formState.placeName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  // 刪除按鈕
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(diaryFormProvider.notifier)
                            .updatePlace(
                              placeId: null,
                              placeName: null,
                              placeAddress: null,
                              latitude: null,
                              longitude: null,
                            );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_location_alt,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text('選擇地點', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
      ),
    );
  }

  /// 圖片縮圖
  Widget _buildImageThumbnail(File image, int index, double size) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// 添加圖片按鈕
  Widget _buildAddImageButton(double size) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text('添加照片', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
