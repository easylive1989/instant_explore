import 'package:flutter/material.dart';

/// 標籤輸入元件
class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? hintText;
  final int maxTags;
  final List<String>? suggestedTags;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.hintText,
    this.maxTags = 10,
    this.suggestedTags,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

/// 預設的常用標籤建議
const List<String> kDefaultSuggestedTags = [
  '早餐',
  '午餐',
  '晚餐',
  '咖啡廳',
  '日式',
  '中式',
  '西式',
  '甜點',
  '飲料',
  '美景',
];

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;

    // 檢查是否已存在
    if (widget.tags.contains(trimmedTag)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('標籤「$trimmedTag」已存在')));
      _controller.clear();
      return;
    }

    // 檢查是否超過數量限制
    if (widget.tags.length >= widget.maxTags) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('最多只能新增 ${widget.maxTags} 個標籤')));
      return;
    }

    widget.onTagsChanged([...widget.tags, trimmedTag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final updatedTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(updatedTags);
  }

  List<String> get _availableSuggestions {
    final suggestions = widget.suggestedTags ?? kDefaultSuggestedTags;
    return suggestions.where((tag) => !widget.tags.contains(tag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已選標籤顯示區域
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text(tag),
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: theme.colorScheme.primaryContainer,
                deleteIconColor: theme.colorScheme.onPrimaryContainer,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // 常用標籤建議
        if (_availableSuggestions.isNotEmpty &&
            widget.tags.length < widget.maxTags) ...[
          Text(
            '常用標籤',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: _availableSuggestions.take(8).map((tag) {
              return ActionChip(
                label: Text(tag),
                labelStyle: theme.textTheme.bodySmall,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                avatar: Icon(
                  Icons.add,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => _addTag(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // 輸入框
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? '輸入自訂標籤後按 Enter',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _addTag(_controller.text),
              tooltip: '新增標籤',
            ),
          ),
          onSubmitted: _addTag,
          textInputAction: TextInputAction.done,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.tags.length}/${widget.maxTags} 個標籤',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.tags.isNotEmpty)
              TextButton(
                onPressed: () => widget.onTagsChanged([]),
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
          ],
        ),
      ],
    );
  }
}
