import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/core/utils/ui_utils.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_detail_header.dart';
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

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
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
          // Header - 純色背景
          DiaryDetailHeader(
            entry: _currentEntry,
            isDeleting: _isDeleting,
            onEdit: _editDiary,
            onDelete: _deleteDiary,
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
                    // 1. 內容（Quill 富文本）
                    DiaryContentSection(content: _currentEntry.content),

                    // 2. 照片集（顯示所有照片）
                    DiaryPhotoGrid(
                      imagePaths: _currentEntry.imagePaths,
                      imageUploadService: imageUploadService,
                    ),

                    // 3. 地點資訊 + 地圖（整合）
                    DiaryMapSection(entry: _currentEntry),

                    // 4. 標籤
                    if (_currentEntry.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _currentEntry.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ThemeConfig.neutralBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: ThemeConfig.neutralText),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
