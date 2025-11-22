import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/features/places/screens/place_picker_screen.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';
import 'package:travel_diary/features/diary/widgets/tag_input.dart';
import 'package:travel_diary/features/diary/widgets/image_picker_widget.dart';
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
  List<String> _tags = [];
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

  void _loadExistingEntry() {
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
    _tags = List.from(entry.tags);
    _placeId = entry.placeId;
    _placeName = entry.placeName;
    _placeAddress = entry.placeAddress;
    _latitude = entry.latitude;
    _longitude = entry.longitude;
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
      for (final tagName in _tags) {
        final tag = await _repository.createTag(tagName);
        await _repository.addTagToDiary(savedEntry.id, tag.id);
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

            // 造訪日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('造訪日期'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_visitDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
            ),
            const Divider(),

            // 造訪時間
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('造訪時間'),
              subtitle: Text(DateFormat('HH:mm').format(_visitDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectTime,
            ),
            const Divider(),

            // 地點選擇
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on),
              title: const Text('地點'),
              subtitle: Text(_placeName ?? '點擊選擇地點'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectPlace,
            ),
            const Divider(),

            const SizedBox(height: 24),

            // 照片
            ImagePickerWidget(
              images: _selectedImages,
              onAddImage: _pickImages,
              onRemoveImage: _removeImage,
              maxImages: 5,
            ),
            const SizedBox(height: 24),

            // 內容（富文本編輯器）
            RichTextEditor(
              controller: _contentController,
              hintText: '分享你的心得與感想...',
              maxLength: 1000,
              height: 224,
            ),
            const SizedBox(height: 24),

            // 標籤
            TagInput(
              tags: _tags,
              onTagsChanged: (newTags) {
                setState(() {
                  _tags = newTags;
                });
              },
              hintText: '新增標籤 (例如:早餐、咖啡廳、日式)',
              maxTags: 10,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
