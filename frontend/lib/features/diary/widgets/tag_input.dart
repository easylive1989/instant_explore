import 'package:flutter/material.dart';

/// 標籤輸入元件
class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? hintText;
  final int maxTags;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.hintText,
    this.maxTags = 10,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標籤顯示區域
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        // 輸入框
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? '輸入標籤後按 Enter',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_controller.text),
            ),
          ),
          onSubmitted: _addTag,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.tags.length}/${widget.maxTags} 個標籤',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
