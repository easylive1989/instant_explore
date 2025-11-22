import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

class DiaryInfoSection extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryInfoSection({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy年MM月dd日');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期與評分
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: ThemeConfig.accentColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              dateFormat.format(entry.visitDate),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ThemeConfig.neutralText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 地點資訊
        if (entry.placeName != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: ThemeConfig.accentColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.placeName!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ThemeConfig.neutralText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.placeAddress != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.placeAddress!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.neutralText.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 標籤
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ThemeConfig.neutralText,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
