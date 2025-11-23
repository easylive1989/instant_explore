import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/core/utils/iterator_extensions.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/shared/widgets/full_image_viewer.dart';

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
    if (imagePaths.isEmpty) {
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
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: imagePaths
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  return GestureDetector(
                    onTap: () {
                      // 開啟圖片查看器
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullImageViewer.network(
                            imageUrls: imagePaths
                                .map((p) => imageUploadService.getImageUrl(p))
                                .toList(),
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        width: 150,
                        height: 150,
                        imageUrl: imageUploadService.getImageUrl(path),
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
                })
                .joinWith<Widget>(const SizedBox(width: AppSpacing.sm))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
