import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';

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
            if (entry.imagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
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
                entry.imagePaths.isEmpty ? AppSpacing.md : AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 地點資訊（移到上方）
                  if (entry.placeName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // 標題（移到下方）
                  Text(
                    entry.title,
                    style: theme.textTheme.titleLarge?.copyWith(
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
