import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/tags/models/tag.dart';
import 'package:travel_diary/features/tags/providers/tag_provider.dart';
import 'package:travel_diary/features/tags/widgets/tag_chip.dart';
import 'package:travel_diary/features/tags/screens/tag_management_screen.dart';

/// 標籤選擇器元件
///
/// 從資料庫載入可用標籤，支援：
/// - 快速選擇已有標籤
/// - 跳轉到標籤管理畫面新增標籤
class TagSelector extends ConsumerWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsChanged;
  final int maxTags;

  const TagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.maxTags = 10,
  });

  void _toggleTag(String tagId) {
    if (selectedTagIds.contains(tagId)) {
      // 移除標籤
      onTagsChanged(selectedTagIds.where((id) => id != tagId).toList());
    } else {
      // 新增標籤
      if (selectedTagIds.length < maxTags) {
        onTagsChanged([...selectedTagIds, tagId]);
      }
    }
  }

  void _navigateToTagManagement(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TagManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagState = ref.watch(tagNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題列
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '標籤 (${selectedTagIds.length}/$maxTags)',
              style: theme.textTheme.titleSmall,
            ),
            TextButton.icon(
              onPressed: () => _navigateToTagManagement(context),
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('管理標籤'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 標籤內容
        if (tagState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (tagState.error != null)
          _buildErrorWidget(context, theme, tagState.error!)
        else
          _buildTagContent(context, theme, tagState.tags),
      ],
    );
  }

  Widget _buildTagContent(
    BuildContext context,
    ThemeData theme,
    List<Tag> tags,
  ) {
    if (tags.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    // 分離已選和未選標籤
    final selectedTags = tags
        .where((tag) => selectedTagIds.contains(tag.id))
        .toList();
    final availableTags = tags
        .where((tag) => !selectedTagIds.contains(tag.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已選標籤
        if (selectedTags.isNotEmpty) ...[
          Text(
            '已選標籤',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: selectedTags.map((tag) {
              return TagChip(
                label: tag.name,
                selected: true,
                onDelete: () => _toggleTag(tag.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 可用標籤
        if (availableTags.isNotEmpty && selectedTagIds.length < maxTags) ...[
          Text(
            '可用標籤',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: availableTags.map((tag) {
              return TagChip(
                label: tag.name,
                selected: false,
                showAddIcon: true,
                onTap: () => _toggleTag(tag.id),
              );
            }).toList(),
          ),
        ],

        // 提示訊息
        if (selectedTagIds.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '點擊標籤快速新增，或前往「管理標籤」建立新標籤',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // 清除全部按鈕
        if (selectedTagIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onTagsChanged([]),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '清除全部',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.label_outline,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('尚未建立標籤', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '前往「管理標籤」建立您的第一個標籤',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToTagManagement(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('建立標籤'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    ThemeData theme,
    Object error,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '載入標籤失敗: ${error.toString()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
