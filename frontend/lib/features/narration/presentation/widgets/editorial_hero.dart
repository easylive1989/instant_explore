import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/shared/widgets/journal/journal_category.dart';
import 'package:flutter/material.dart';

/// Hero scrim (design token `.hero__scrim`): a top-and-bottom darkening so
/// overlaid back buttons and captions stay legible over any photo.
const LinearGradient kEditorialHeroScrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0x470F0B07),
    Color(0x000F0B07),
    Color(0x8C0F0B07),
    Color(0xEB0F0B07),
  ],
  stops: [0.0, 0.28, 0.78, 1.0],
);

/// Fills an editorial hero: a captured image if present, else the place photo,
/// else a category-tinted gradient with a centered glyph.
///
/// Draws only the background — compose the scrim ([kEditorialHeroScrim]) and
/// any caption on top inside a [Stack].
class EditorialHeroBackground extends StatelessWidget {
  /// The place whose photo (or category glyph) fills the hero.
  final Place place;

  /// An in-memory captured image that takes precedence over
  /// [place.primaryPhoto].
  final Uint8List? capturedImageBytes;

  const EditorialHeroBackground({
    super.key,
    required this.place,
    this.capturedImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (capturedImageBytes != null) {
      return Image.memory(capturedImageBytes!, fit: BoxFit.cover);
    }

    final photoUrl = place.primaryPhoto?.url;
    final glyph = _GlyphBackground(category: place.category.journalCategory);
    if (photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        cacheManager: PlaceImageCacheManager.instance,
        placeholder: (context, url) => glyph,
        errorWidget: (context, url, error) => glyph,
      );
    }

    return glyph;
  }
}

/// Photo-less hero fill: a category-tinted dark gradient with a centered glyph
/// (design: `linear-gradient(160deg, var(--cat-*-ink), var(--ink-bg))`).
class _GlyphBackground extends StatelessWidget {
  final JournalCategory category;

  const _GlyphBackground({required this.category});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.ink, tokens?.inkBg ?? const Color(0xFF1B1611)],
        ),
      ),
      child: Center(
        child: Icon(
          category.icon,
          size: 34,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
