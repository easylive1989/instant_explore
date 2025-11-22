import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

class DiaryPhotoGrid extends StatelessWidget {
  final List<String> imagePaths;
  final ImageUploadService imageUploadService;

  const DiaryPhotoGrid({
    super.key,
    required this.imagePaths,
    required this.imageUploadService,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.length <= 1) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '照片 (${imagePaths.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            color: ThemeConfig.neutralText.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeConfig.neutralBorder,
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: imageUploadService.getImageUrl(imagePaths[index]),
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
                      Icons.error_outline,
                      color: ThemeConfig.neutralBorder,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
