import 'package:context_app/shared/widgets/journal/journal_category.dart';
import 'package:flutter/material.dart';

/// Square placeholder thumbnail for places without a photo: the category
/// background tint with its glyph centered.
class GlyphThumb extends StatelessWidget {
  const GlyphThumb({
    super.key,
    required this.category,
    this.size = 64,
    this.borderRadius = 12,
  });

  final JournalCategory category;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('glyph-thumb-surface'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(category.icon, size: size * 0.5, color: category.ink),
      ),
    );
  }
}
