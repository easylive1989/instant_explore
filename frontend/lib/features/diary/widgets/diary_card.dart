import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../../images/services/image_upload_service.dart';
import '../../../core/constants/spacing_constants.dart';
import '../../../core/config/theme_config.dart';

/// 日記卡片元件 - 極簡風格
class DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final ImageUploadService imageUploadService;

  const DiaryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.imageUploadService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      margin: EdgeInsets.only(
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
            if (entry.imagePaths.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUploadService.getImageUrl(
                        entry.imagePaths.first,
                      ),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ThemeConfig.neutralLight,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ThemeConfig.neutralLight,
                        child: Icon(
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
                entry.imagePaths.isEmpty ? AppSpacing.md : AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題與評分
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: ThemeConfig.neutralText,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.rating != null) ...[
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeConfig.neutralLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: ThemeConfig.accentColor,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                entry.rating.toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ThemeConfig.neutralText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),

                  // 地點和日期 - 合併為一行
                  Row(
                    children: [
                      if (entry.placeName != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: ThemeConfig.accentColor,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            entry.placeName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ThemeConfig.neutralText.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                      ],
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: ThemeConfig.accentColor,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        dateFormat.format(entry.visitDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.neutralText.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  // 標籤 - 極簡風格
                  if (entry.tags.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: entry.tags.take(3).map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeConfig.neutralLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: ThemeConfig.neutralBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ThemeConfig.neutralText.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
