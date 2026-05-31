import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/journal/category_tag.dart';
import 'package:context_app/shared/widgets/journal/glyph_thumb.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const List<BoxShadow> _kCardShadow = [
  BoxShadow(color: Color(0x17281E12), offset: Offset(0, 6), blurRadius: 18),
];

/// 分析結果卡片（Field Journal）
///
/// 顯示 AI 分析後的景點資訊（不含按鈕）。
class AnalysisResultCard extends StatelessWidget {
  final Place place;

  const AnalysisResultCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final radius = tokens?.rLg ?? 16;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(BorderSide(color: cs.outlineVariant)),
        boxShadow: tokens?.e2 ?? _kCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Thumb(place: place),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.notoSerifTc(
                        color: cs.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CategoryTag(category: place.category.journalCategory),
                  ],
                ),
              ),
            ],
          ),
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: cs.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final photoUrl = place.primaryPhoto?.url;
    if (photoUrl == null) {
      return GlyphThumb(
        category: place.category.journalCategory,
        size: 64,
        borderRadius: 12,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => GlyphThumb(
          category: place.category.journalCategory,
          size: 64,
          borderRadius: 12,
        ),
      ),
    );
  }
}
