import 'dart:io';
import 'package:flutter/material.dart';

/// 圖片選擇與預覽元件
class ImagePickerWidget extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAddImage;
  final ValueChanged<int> onRemoveImage;
  final int maxImages;
  final double? imageSize;

  const ImagePickerWidget({
    super.key,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
    this.maxImages = 5,
    this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = images.length < maxImages;
    final size = imageSize ?? 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '照片 (${images.length}/$maxImages)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: size,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 新增按鈕
              if (index == images.length && canAddMore) {
                return _buildAddButton(context, size);
              }

              // 圖片預覽
              return _buildImagePreview(context, images[index], index, size);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, double size) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onAddImage,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: size * 0.35,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                '新增',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(
    BuildContext context,
    File image,
    int index,
    double size,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          // 圖片
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          // 刪除按鈕
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveImage(index),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          // 順序標記
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
