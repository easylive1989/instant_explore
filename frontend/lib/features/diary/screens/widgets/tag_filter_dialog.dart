import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';

/// 標籤篩選對話框
///
/// 讓使用者選擇要篩選的標籤
class TagFilterDialog extends ConsumerWidget {
  const TagFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryListProvider);
    final notifier = ref.read(diaryListProvider.notifier);

    return AlertDialog(
      title: const Text('標籤篩選'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: state.allTags.map((tag) {
            final isSelected = state.selectedTagIds.contains(tag.id);
            return CheckboxListTile(
              title: Text(tag.name),
              value: isSelected,
              onChanged: (value) {
                notifier.toggleTagFilter(tag.id);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        if (state.selectedTagIds.isNotEmpty)
          TextButton(
            onPressed: () {
              notifier.clearTagFilters();
              Navigator.of(context).pop();
            },
            child: const Text('清除篩選'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}
