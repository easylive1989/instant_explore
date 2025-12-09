import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/core/services/gemini_service.dart';
import 'package:travel_diary/features/places/screens/place_picker_screen.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/tags/widgets/tag_selector.dart';
import 'package:travel_diary/features/diary/widgets/rich_text_editor.dart';
import 'package:travel_diary/features/places/models/place.dart';
import 'package:travel_diary/features/diary/providers/diary_form_provider.dart';
import 'package:travel_diary/features/diary/providers/diary_crud_provider.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'package:travel_diary/features/images/providers/image_providers.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

/// 日記新增/編輯畫面
class DiaryCreateScreen extends ConsumerStatefulWidget {
  final String? diaryId;

  const DiaryCreateScreen({super.key, this.diaryId});

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isBottomSheetExpanded = false;
  double? _sheetHeight;
  bool _isEditing = false;
  bool _isLoadingEntry = false;
  bool _isGenerating = false; // AI 生成狀態
  DiaryEntry? _existingEntry; // 編輯模式時儲存載入的 entry

  @override
  void initState() {
    super.initState();
    _isEditing = widget.diaryId != null;

    // 延遲初始化,確保 provider 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadExistingEntry();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadExistingEntry() async {
    setState(() {
      _isLoadingEntry = true;
    });

    try {
      // 從 repository 載入日記資料
      final repository = ref.read(diaryRepositoryProvider);
      final entry = await repository.getDiaryEntryById(widget.diaryId!);

      if (entry == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('diary_create.diary_not_found'))),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 儲存 entry 以供後續使用
      _existingEntry = entry;

      // 使用 form provider 載入資料
      ref.read(diaryFormProvider.notifier).loadFromEntry(entry);

      // 載入標籤 ID
      try {
        final diaryTags = await repository.getTagsForDiary(entry.id);
        ref
            .read(diaryFormProvider.notifier)
            .updateTags(diaryTags.map((tag) => tag.id).toList());
      } catch (e) {
        // 標籤載入失敗時使用空列表
      }
      // 注意:現有圖片不會載入到 selectedImages,因為它們已經在 Storage
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'diary_create.load_diary_failed',
                args: [e.toString()],
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEntry = false;
        });
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'diary_create.pick_image_failed',
                args: [e.toString()],
              ),
            ),
          ),
        );
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
                        context.tr('common.cancel'),
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
                        context.tr('common.confirm'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('diary_create.select_place_first'))),
      );
      return;
    }

    // 將 Quill Delta 轉換為 JSON 字串
    final deltaJson = jsonEncode(
      formState.contentController.document.toDelta().toJson(),
    );

    DiaryEntry? savedEntry;

    if (_isEditing && _existingEntry != null) {
      savedEntry = await ref
          .read(diaryCrudProvider.notifier)
          .updateDiary(
            diaryId: _existingEntry!.id,
            userId: _existingEntry!.userId,
            contentJson: deltaJson,
            visitDate: formState.visitDate,
            tagIds: formState.selectedTagIds,
            newImages: formState.selectedImages,
            placeId: formState.placeId,
            placeName: formState.placeName,
            placeAddress: formState.placeAddress,
            latitude: formState.latitude,
            longitude: formState.longitude,
            createdAt: _existingEntry!.createdAt,
          );
    } else {
      savedEntry = await ref
          .read(diaryCrudProvider.notifier)
          .createDiary(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? context.tr('diary_create.diary_updated')
                : context.tr('diary_create.diary_created'),
          ),
        ),
      );
      Navigator.of(context).pop(true); // 返回 true 表示已儲存
    }
  }

  Future<void> _generateAIDescription() async {
    final formState = ref.read(diaryFormProvider);
    if (formState.placeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('diary_create.select_place_first'))),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final place = Place(
        id: formState.placeId!,
        name: formState.placeName ?? '',
        formattedAddress: formState.placeAddress ?? '',
        location: PlaceLocation(
          latitude: formState.latitude!,
          longitude: formState.longitude!,
        ),
        types: [],
        photos: [],
      );

      final geminiService = ref.read(geminiServiceProvider);
      final description = await geminiService.generateDiaryDescription(place);

      final controller = formState.contentController;
      controller.document.delete(0, controller.document.length);
      controller.document.insert(0, description);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('diary_create.generate_failed', args: [e.toString()]),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
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

    // 載入中狀態
    if (_isLoadingEntry) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    const double collapsedHeight = 85.0;
    final double expandedHeight = screenHeight * 0.7;

    _sheetHeight ??= collapsedHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? context.tr('diary.edit') : context.tr('diary.create'),
        ),
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
            IconButton(onPressed: _saveDiary, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, collapsedHeight + 20),
          child: _buildGroup1(formState),
        ),
      ),
      bottomSheet: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: _sheetHeight!,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isBottomSheetExpanded = !_isBottomSheetExpanded;
                  _sheetHeight = _isBottomSheetExpanded
                      ? expandedHeight
                      : collapsedHeight;
                });
              },
              onVerticalDragUpdate: (details) {
                setState(() {
                  _sheetHeight = _sheetHeight! - details.delta.dy;
                  _sheetHeight = _sheetHeight!.clamp(
                    collapsedHeight,
                    expandedHeight,
                  );
                });
              },
              onVerticalDragEnd: (details) {
                final midPoint = (expandedHeight + collapsedHeight) / 2;
                final shouldExpand =
                    details.primaryVelocity! < -300 ||
                    (details.primaryVelocity!.abs() < 300 &&
                        _sheetHeight! > midPoint);

                setState(() {
                  _isBottomSheetExpanded = shouldExpand;
                  _sheetHeight = shouldExpand
                      ? expandedHeight
                      : collapsedHeight;
                });
              },
              child: SizedBox(
                height: 40,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _buildGroup2(formState),
                  const SizedBox(height: 16),
                  _buildGroup3(formState),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Group 1: 標題內文與時間
  Widget _buildGroup1(DiaryFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _selectDateTime,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy/MM/dd').format(formState.visitDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('diary.content'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_isGenerating)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: _generateAIDescription,
                icon: const Icon(Icons.auto_awesome),
                tooltip: context.tr('diary_create.generate_with_ai'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 內容(富文本編輯器)
        RichTextEditor(
          controller: formState.contentController,
          hintText: context.tr('diary.contentHint'),
          height: MediaQuery.sizeOf(context).height - 450,
        ),
        const SizedBox(height: 16),
      ],
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
          Text(
            context.tr('diary.locationAndPhotos'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                  Text(
                    context.tr('diary.selectLocation'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
            Text(
              context.tr('diary.addPhotos'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
