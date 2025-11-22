import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/utils/diary_date_grouper.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/diary/screens/widgets/timeline_item_widget.dart';

/// 時間軸日期分組 Widget
///
/// 顯示一個日期下的所有日記條目
class TimelineGroupWidget extends StatelessWidget {
  const TimelineGroupWidget({
    super.key,
    required this.date,
    required this.entries,
    required this.notifier,
    required this.imageUploadService,
  });

  final String date; // 格式：'yyyy-MM-dd'
  final List<DiaryEntry> entries;
  final DiaryListNotifier notifier;
  final ImageUploadService imageUploadService;

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.parse(date);
    final displayDate = DateFormat('yyyy年MM月dd日').format(dateTime);
    final weekday = DiaryDateGrouper.getWeekdayName(dateTime.weekday);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期標頭
          _buildDateHeader(context, displayDate, weekday),

          // 時間軸上的日記卡片
          ...entries.map(
            (entry) => TimelineItemWidget(
              entry: entry,
              notifier: notifier,
              imageUploadService: imageUploadService,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立日期標頭
  Widget _buildDateHeader(
    BuildContext context,
    String displayDate,
    String weekday,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.timelineCardIndent,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            displayDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ThemeConfig.neutralText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            weekday,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeConfig.neutralText.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
