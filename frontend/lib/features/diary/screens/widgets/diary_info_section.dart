import 'package:flutter/material.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

class DiaryInfoSection extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryInfoSection({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}
