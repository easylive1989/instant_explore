import 'package:context_app/shared/widgets/journal/journal_category.dart';
import 'package:flutter/material.dart';

/// A pill-shaped category label: glyph + name on a category-tinted surface.
///
/// Set [onPhoto] when the tag sits over an image; it switches to a dark
/// translucent surface with white text for legibility.
class CategoryTag extends StatelessWidget {
  const CategoryTag({super.key, required this.category, this.onPhoto = false});

  final JournalCategory category;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final fg = onPhoto ? Colors.white : category.ink;
    final bg = onPhoto ? const Color(0x80141008) : category.bg;

    return Container(
      key: const ValueKey('category-tag-surface'),
      height: 28,
      padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
