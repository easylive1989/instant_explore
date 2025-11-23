import 'package:flutter/material.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

class DiaryDetailHeader extends StatelessWidget {
  final DiaryEntry entry;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiaryDetailHeader({
    super.key,
    required this.entry,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.black87),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Text(
        entry.title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (isDeleting)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
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
    );
  }
}
