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
  @override
  void initState() {
    super.initState();
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

    // 使用 Provider 處理刪除邏輯
    final success = await ref
        .read(diaryDetailProvider(widget.entry).notifier)
        .deleteDiary();

    if (mounted && success) {
      UiUtils.showSuccessSnackBar(context, '日記已刪除');
      Navigator.of(context).pop(true); // 返回 true 表示已刪除
    }
  }

  Future<void> _editDiary() async {
    final detailState = ref.read(diaryDetailProvider(widget.entry));

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            DiaryCreateScreen(existingEntry: detailState.entry),
      ),
    );

    if (result == true && mounted) {
      // 使用 Provider 重新載入日記資料
      await ref.read(diaryDetailProvider(widget.entry).notifier).reloadDiary();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 Provider 狀態
    final detailState = ref.watch(diaryDetailProvider(widget.entry));

    // 監聽錯誤訊息
    ref.listen<DiaryDetailState>(diaryDetailProvider(widget.entry), (
      previous,
      next,
    ) {
      if (next.error != null && mounted) {
        UiUtils.showErrorSnackBar(context, next.error!);
      }
    });

    // 取得圖片 URL 列表
    final imageUrls = ref
        .read(diaryDetailProvider(widget.entry).notifier)
        .getImageUrls();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header - 純色背景
          DiaryDetailHeader(
            entry: detailState.entry,
            isDeleting: detailState.isDeleting,
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
                    DiaryContentSection(content: detailState.entry.content),

                    // 2. 照片集（顯示所有照片）
                    DiaryPhotoGrid(imageUrls: imageUrls),

                    // 3. 地點資訊 + 地圖（整合）
                    DiaryMapSection(entry: detailState.entry),

                    // 4. 標籤
                    if (detailState.entry.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: detailState.entry.tags.map((tag) {
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
