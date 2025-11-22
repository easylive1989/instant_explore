import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

class DiaryDetailHeader extends StatelessWidget {
  final DiaryEntry entry;
  final Color iconColor;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ImageUploadService imageUploadService;

  const DiaryDetailHeader({
    super.key,
    required this.entry,
    required this.iconColor,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
    required this.imageUploadService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      iconTheme: IconThemeData(color: iconColor),
      actions: [
        if (isDeleting)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: iconColor),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.black),
                    SizedBox(width: 12),
                    Text('編輯', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('刪除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          entry.title,
          style: const TextStyle(
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: entry.imagePaths.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUploadService.getImageUrl(
                      entry.imagePaths.first,
                    ),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                  // 漸層遮罩
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black38],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
      ),
    );
  }
}
