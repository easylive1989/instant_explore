import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/core/utils/image_brightness_helper.dart';
import 'package:travel_diary/core/utils/ui_utils.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_detail_header.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_info_section.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_content_section.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_photo_grid.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_map_section.dart';

/// 日記詳情畫面
class DiaryDetailScreen extends ConsumerStatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  late DiaryEntry _currentEntry;
  bool _isDeleting = false;
  Color _iconColor = Colors.white; // 預設白色

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _analyzeImageBrightness();
  }

  /// 分析圖片亮度並設定 icon 顏色
  Future<void> _analyzeImageBrightness() async {
    if (_currentEntry.imagePaths.isEmpty) {
      // 沒有圖片時使用黑色 icon（配合淺色背景）
      if (mounted) {
        setState(() {
          _iconColor = Colors.black;
        });
      }
      return;
    }

    try {
      final imageUploadService = ref.read(imageUploadServiceProvider);

      final imageUrl = imageUploadService.getImageUrl(
        _currentEntry.imagePaths.first,
      );
      final imageProvider = CachedNetworkImageProvider(imageUrl);

      final foregroundColor = await ImageBrightnessHelper.getForegroundColor(
        imageProvider,
        defaultColor: Colors.white,
      );

      if (mounted) {
        setState(() {
          _iconColor = foregroundColor;
        });
      }
    } catch (e) {
      debugPrint('分析圖片亮度失敗: $e');
      // 保持預設白色
    }
  }

  Future<void> _deleteDiary() async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: '確認刪除',
      content: '確定要刪除這篇日記嗎?此操作無法復原。',
      confirmText: '刪除',
      isDangerous: true,
    );

    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final imageUploadService = ref.read(imageUploadServiceProvider);
      final repository = ref.read(diaryRepositoryProvider);

      // 刪除圖片
      if (_currentEntry.imagePaths.isNotEmpty) {
        await imageUploadService.deleteMultipleImages(_currentEntry.imagePaths);
      }

      // 刪除日記
      await repository.deleteDiaryEntry(_currentEntry.id);

      if (mounted) {
        UiUtils.showSuccessSnackBar(context, '日記已刪除');
        Navigator.of(context).pop(true); // 返回 true 表示已刪除
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        UiUtils.showErrorSnackBar(context, '刪除失敗: $e');
      }
    }
  }

  Future<void> _editDiary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryCreateScreen(existingEntry: _currentEntry),
      ),
    );

    if (result == true && mounted) {
      // 重新載入日記資料
      try {
        final repository = ref.read(diaryRepositoryProvider);

        final updatedEntry = await repository.getDiaryEntryById(
          _currentEntry.id,
        );
        if (updatedEntry != null) {
          setState(() {
            _currentEntry = updatedEntry;
          });
          // 重新分析圖片亮度
          _analyzeImageBrightness();
        }
      } catch (e) {
        if (mounted) {
          UiUtils.showErrorSnackBar(context, '重新載入失敗: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUploadService = ref.read(imageUploadServiceProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          DiaryDetailHeader(
            entry: _currentEntry,
            iconColor: _iconColor,
            isDeleting: _isDeleting,
            onEdit: _editDiary,
            onDelete: _deleteDiary,
            imageUploadService: imageUploadService,
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeConfig.neutralBorder, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期、地點、標籤
                    DiaryInfoSection(entry: _currentEntry),

                    // 內容（Quill 富文本）
                    DiaryContentSection(content: _currentEntry.content),

                    // 圖片集
                    DiaryPhotoGrid(
                      imagePaths: _currentEntry.imagePaths,
                      imageUploadService: imageUploadService,
                    ),

                    // 地圖
                    DiaryMapSection(entry: _currentEntry),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
