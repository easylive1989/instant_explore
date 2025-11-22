import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/features/places/screens/place_picker_screen.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';
import 'package:travel_diary/features/tags/widgets/tag_selector.dart';
import 'package:travel_diary/features/diary/widgets/rich_text_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:travel_diary/features/images/services/image_picker_service.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/places/models/place.dart';

/// 日記新增/編輯畫面
class DiaryCreateScreen extends ConsumerStatefulWidget {
  final DiaryEntry? existingEntry;

  const DiaryCreateScreen({super.key, this.existingEntry});

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final QuillController _contentController;

  // 服務
  late final DiaryRepository _repository;
  late final ImagePickerService _imagePickerService;
  late final ImageUploadService _imageUploadService;

  // 表單欄位
  DateTime _visitDate = DateTime.now();
  List<String> _selectedTagIds = [];
  final List<File> _selectedImages = [];
  String? _placeId;
  String? _placeName;
  String? _placeAddress;
  double? _latitude;
  double? _longitude;

  // 狀態
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _repository = DiaryRepositoryImpl();
    _imagePickerService = ImagePickerService();
    _imageUploadService = ImageUploadService();
    _contentController = QuillController.basic();

    _isEditing = widget.existingEntry != null;
    if (_isEditing) {
      _loadExistingEntry();
    }
  }

  Future<void> _loadExistingEntry() async {
    final entry = widget.existingEntry!;
    _titleController.text = entry.title;

    // 載入 Quill 內容
    if (entry.content != null && entry.content!.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(entry.content!);
        _contentController.document = Document.fromJson(deltaJson);
      } catch (e) {
        // 如果是舊的純文字內容，直接設為純文字
        _contentController.document = Document()..insert(0, entry.content!);
      }
    }

    _visitDate = entry.visitDate;
    _placeId = entry.placeId;
    _placeName = entry.placeName;
    _placeAddress = entry.placeAddress;
    _latitude = entry.latitude;
    _longitude = entry.longitude;

    // 載入標籤 ID
    try {
      final diaryTags = await _repository.getTagsForDiary(entry.id);
      setState(() {
        _selectedTagIds = diaryTags.map((tag) => tag.id).toList();
      });
    } catch (e) {
      // 標籤載入失敗時使用空列表
      _selectedTagIds = [];
    }
    // 注意:現有圖片不會載入到 _selectedImages,因為它們已經在 Storage
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePickerService.pickMultipleImagesFromGallery(
        maxImages: 5 - _selectedImages.length,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
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
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        // 保留原本的時間部分,只更新日期
        _visitDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _visitDate.hour,
          _visitDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visitDate),
    );

    if (pickedTime != null) {
      setState(() {
        // 保留原本的日期部分,只更新時間
        _visitDate = DateTime(
          _visitDate.year,
          _visitDate.month,
          _visitDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _selectPlace() async {
    final selectedPlace = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (context) => const PlacePickerScreen()),
    );

    if (selectedPlace != null) {
      setState(() {
        _placeId = selectedPlace.id;
        _placeName = selectedPlace.name;
        _placeAddress = selectedPlace.formattedAddress;
        _latitude = selectedPlace.location.latitude;
        _longitude = selectedPlace.location.longitude;
      });
    }
  }

  Future<void> _saveDiary() async {
    if (!_formKey.currentState!.validate()) return;

    if (_placeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇地點')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. 建立或更新日記資料
      // 將 Quill Delta 轉換為 JSON 字串
      final deltaJson = jsonEncode(
        _contentController.document.toDelta().toJson(),
      );

      final diaryData = DiaryEntry(
        id: widget.existingEntry?.id ?? '',
        userId: widget.existingEntry?.userId ?? '',
        title: _titleController.text.trim(),
        content: deltaJson,
        placeId: _placeId,
        placeName: _placeName,
        placeAddress: _placeAddress,
        latitude: _latitude,
        longitude: _longitude,
        visitDate: _visitDate,
        createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      DiaryEntry savedEntry;
      if (_isEditing) {
        savedEntry = await _repository.updateDiaryEntry(diaryData);
      } else {
        savedEntry = await _repository.createDiaryEntry(diaryData);
      }

      // 2. 上傳圖片
      if (_selectedImages.isNotEmpty) {
        final uploadedPaths = await _imageUploadService.uploadMultipleImages(
          imageFiles: _selectedImages,
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
      for (final tagId in _selectedTagIds) {
        await _repository.addTagToDiary(savedEntry.id, tagId);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditing ? '日記已更新' : '日記已建立')));
        Navigator.of(context).pop(true); // 返回 true 表示已儲存
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('儲存失敗: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編輯日記' : '新增日記'),
        actions: [
          if (_isSaving)
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
            _buildGroup1(),
            const SizedBox(height: 16),
            _buildGroup2(),
            const SizedBox(height: 16),
            _buildGroup3(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Group 1: 標題內文與時間
  Widget _buildGroup1() {
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
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '標題',
              hintText: '今天去了哪裡?',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
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
            controller: _contentController,
            hintText: '分享你的心得與感想...',
            maxLength: 1000,
            height: 200,
          ),
          const SizedBox(height: 16),

          // 日期與時間
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
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
                          Icons.calendar_today,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '日期',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(_visitDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
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
                          Icons.access_time,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '時間',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat('HH:mm').format(_visitDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Group 2: 地點與圖片混合顯示
  Widget _buildGroup2() {
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
          _buildPlaceAndImageGrid(),
        ],
      ),
    );
  }

  /// Group 3: 標籤
  Widget _buildGroup3() {
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
        selectedTagIds: _selectedTagIds,
        onTagsChanged: (newTagIds) {
          setState(() {
            _selectedTagIds = newTagIds;
          });
        },
        maxTags: 10,
      ),
    );
  }

  /// 地點與圖片混合網格
  Widget _buildPlaceAndImageGrid() {
    const imageSize = 90.0;
    const spacing = 8.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        // 地點縮圖 (第一個位置)
        _buildPlaceThumbnail(imageSize),
        // 圖片
        ..._selectedImages.asMap().entries.map(
          (entry) => _buildImageThumbnail(entry.value, entry.key, imageSize),
        ),
        // 添加圖片按鈕
        if (_selectedImages.length < 5) _buildAddImageButton(imageSize),
      ],
    );
  }

  /// 地點縮圖
  Widget _buildPlaceThumbnail(double size) {
    final hasPlace =
        _placeId != null && _latitude != null && _longitude != null;

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
                        if (_placeName != null)
                          Text(
                            _placeName!,
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
                        setState(() {
                          _placeId = null;
                          _placeName = null;
                          _placeAddress = null;
                          _latitude = null;
                          _longitude = null;
                        });
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
