import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:context_app/features/narration/presentation/widgets/reading_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final palette = ReadingPalette.of(context);
    return AutoScrollTag(
      key: ValueKey(index),
      controller: scrollController,
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: isActive
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -22,
                    top: 6,
                    bottom: 6,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.clay,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    segment.text,
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 20,
                      height: 1.9,
                      fontWeight: FontWeight.w600,
                      color: palette.readInk,
                    ),
                  ),
                ],
              )
            : Text(
                segment.text,
                style: GoogleFonts.notoSerifTc(
                  fontSize: 18.5,
                  height: 1.9,
                  color: palette.readDim,
                ),
              ),
      ),
    );
  }
}
