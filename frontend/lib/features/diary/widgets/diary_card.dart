import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary/features/diary/models/diary_entry_view_data.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';

/// 日記卡片元件 - 極簡風格
class DiaryCard extends StatelessWidget {
  final DiaryEntryViewData entry;
  final VoidCallback onTap;

  const DiaryCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeConfig.neutralBorder, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 圖片 - 帶圓角和內邊距
            if (entry.imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: entry.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ThemeConfig.neutralLight,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ThemeConfig.neutralLight,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: ThemeConfig.neutralBorder,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 內容 - 更多留白
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                entry.imageUrl == null ? AppSpacing.md : AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 地點名稱作為標題
                  if (entry.placeName != null)
                    Text(
                      entry.placeName!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ThemeConfig.neutralText,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
