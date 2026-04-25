import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 單個轉錄文本段落項目
class TranscriptSegmentItem extends StatelessWidget {
  final NarrationSegment segment;
  final bool isActive;
  final AutoScrollController scrollController;
  final int index;

  const TranscriptSegmentItem({
    super.key,
    required this.segment,
    required this.isActive,
    required this.scrollController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AutoScrollTag(
      key: ValueKey(index),
      controller: scrollController,
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: isActive
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -20,
                    top: 6,
                    bottom: 6,
                    width: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    segment.text,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ],
              )
            : Text(
                segment.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  height: 1.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
