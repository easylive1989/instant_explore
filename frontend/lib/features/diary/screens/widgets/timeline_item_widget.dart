import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/widgets/diary_card.dart';
import 'package:travel_diary/features/diary/screens/diary_detail_screen.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

/// 時間軸單一項目 Widget
///
/// 包含時間軸節點、時間標籤和日記卡片
class TimelineItemWidget extends StatelessWidget {
  const TimelineItemWidget({
    super.key,
    required this.entry,
    required this.notifier,
    required this.imageUploadService,
  });

  final DiaryEntry entry;
  final DiaryListNotifier notifier;
  final ImageUploadService imageUploadService;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm').format(entry.visitDate);

    return Stack(
      children: [
        // 時間軸垂直線
        _buildTimelineLine(),

        // 時間軸節點（圓點）
        _buildTimelineDot(context),

        // 時間標籤
        _buildTimeLabel(context, timeText),

        // 日記卡片
        _buildDiaryCard(context),
      ],
    );
  }

  /// 建立時間軸垂直線
  Widget _buildTimelineLine() {
    return Positioned(
      left: AppSpacing.lg,
      top: 0,
      bottom: 0,
      child: Container(
        width: AppSpacing.timelineLineWidth,
        color: ThemeConfig.neutralBorder,
      ),
    );
  }

  /// 建立時間軸節點
  Widget _buildTimelineDot(BuildContext context) {
    return Positioned(
      left: AppSpacing.lg - (AppSpacing.timelineDotSize / 2) + 1,
      top: 0,
      child: Container(
        width: AppSpacing.timelineDotSize,
        height: AppSpacing.timelineDotSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  /// 建立時間標籤
  Widget _buildTimeLabel(BuildContext context, String timeText) {
    return Positioned(
      left: AppSpacing.lg + AppSpacing.timelineDotSize + AppSpacing.xs,
      top: -1,
      child: Text(
        timeText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  /// 建立日記卡片
  Widget _buildDiaryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl, top: AppSpacing.lg),
      child: DiaryCard(
        entry: entry,
        imageUploadService: imageUploadService,
        onTap: () => _navigateToDiaryDetail(context),
      ),
    );
  }

  /// 導航到日記詳情
  Future<void> _navigateToDiaryDetail(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(diaryId: entry.id),
      ),
    );

    if (result == true) {
      notifier.loadDiaries();
    }
  }
}
