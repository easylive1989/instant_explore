import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/providers/diary_detail_provider.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/core/utils/ui_utils.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_content_section.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_photo_grid.dart';
import 'package:travel_diary/features/diary/screens/widgets/diary_map_section.dart';

/// 日記詳情畫面
class DiaryDetailScreen extends ConsumerStatefulWidget {
  final String diaryId;

  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 載入日記資料
    Future.microtask(() {
      ref.read(diaryDetailByIdProvider(widget.diaryId).notifier).loadDiary();
    });
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
        .read(diaryDetailByIdProvider(widget.diaryId).notifier)
        .deleteDiary();

    if (mounted && success) {
      UiUtils.showSuccessSnackBar(context, '日記已刪除');
      Navigator.of(context).pop(true); // 返回 true 表示已刪除
    }
  }

  Future<void> _editDiary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryCreateScreen(diaryId: widget.diaryId),
      ),
    );

    if (result == true && mounted) {
      // 使用 Provider 重新載入日記資料
      await ref
          .read(diaryDetailByIdProvider(widget.diaryId).notifier)
          .reloadDiary();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 Provider 狀態
    final detailState = ref.watch(diaryDetailByIdProvider(widget.diaryId));

    // 監聽錯誤訊息
    ref.listen<DiaryDetailByIdState>(diaryDetailByIdProvider(widget.diaryId), (
      previous,
      next,
    ) {
      if (next.error != null && mounted) {
        UiUtils.showErrorSnackBar(context, next.error!);
      }
    });

    // 載入中狀態
    if (detailState.isLoading) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    // 錯誤狀態
    if (detailState.error != null && detailState.entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('錯誤')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('載入失敗: ${detailState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(diaryDetailByIdProvider(widget.diaryId).notifier)
                      .loadDiary();
                },
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      );
    }

    // 資料不存在
    if (detailState.entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('錯誤')),
        body: const Center(child: Text('找不到日記資料')),
      );
    }

    // 取得圖片 URL 列表
    final imageUrls = ref
        .read(diaryDetailByIdProvider(widget.diaryId).notifier)
        .getImageUrls();

    final entry = detailState.entry!;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header - Cupertino Navigation Bar
            CupertinoSliverNavigationBar(
              largeTitle: Text(entry.title),
              trailing: _buildNavigationBarActions(detailState),
              backgroundColor: ThemeConfig.neutralLight,
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ThemeConfig.neutralBorder,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 內容（Quill 富文本）
                      DiaryContentSection(content: entry.content),

                      // 2. 照片集（顯示所有照片）
                      DiaryPhotoGrid(imageUrls: imageUrls),

                      // 3. 地點資訊 + 地圖（整合）
                      DiaryMapSection(entry: entry),

                      // 4. 標籤
                      if (entry.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: entry.tags.map((tag) {
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
      ),
    );
  }

  Widget _buildNavigationBarActions(DiaryDetailByIdState state) {
    if (state.isDeleting) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showActionSheet(state),
      child: const Icon(
        CupertinoIcons.ellipsis_circle,
        color: ThemeConfig.neutralText,
      ),
    );
  }

  void _showActionSheet(DiaryDetailByIdState state) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editDiary();
            },
            child: const Text('編輯'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteDiary();
            },
            child: const Text('刪除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
      ),
    );
  }
}
