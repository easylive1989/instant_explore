import 'package:flutter/material.dart';

/// 可重用的標籤 Chip 元件
class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool selected;
  final bool showAddIcon;

  const TagChip({
    super.key,
    required this.label,
    this.onDelete,
    this.onTap,
    this.selected = false,
    this.showAddIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 如果有 onTap，使用 ActionChip
    if (onTap != null && onDelete == null) {
      return ActionChip(
        label: Text(label),
        labelStyle: theme.textTheme.bodySmall,
        backgroundColor: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: selected ? 1 : 0.5,
        ),
        avatar: showAddIcon
            ? Icon(Icons.add, size: 16, color: theme.colorScheme.primary)
            : null,
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    // 否則使用普通 Chip
    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
      ),
      backgroundColor: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      deleteIconColor: selected
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onSurfaceVariant,
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: onDelete,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
