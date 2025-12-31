import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 單個轉錄文本段落項目
class TranscriptSegmentItem extends StatelessWidget {
  final NarrationSegment segment;
  final bool isActive;
  final Color primaryColor;
  final AutoScrollController scrollController;
  final int index;

  const TranscriptSegmentItem({
    super.key,
    required this.segment,
    required this.isActive,
    required this.primaryColor,
    required this.scrollController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AutoScrollTag(
      key: ValueKey(index),
      controller: scrollController,
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: isActive
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -20,
                    top: 6,
                    bottom: 6,
                    width: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    segment.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              )
            : Text(
                segment.text,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 20,
                  height: 1.6,
                ),
              ),
      ),
    );
  }
}
