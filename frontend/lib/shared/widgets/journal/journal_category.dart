import 'package:flutter/material.dart';

/// Visual identity for a place category in the Field Journal design:
/// display label, glyph, and colours.
///
/// This is a presentation-layer category distinct from the explore
/// feature's domain `PlaceCategory` (which carries a different taxonomy).
/// The domain→journal mapping is added when the explore screen migrates.
enum JournalCategory {
  nature('自然景觀', Icons.terrain_outlined, Color(0xFF4E6138), Color(0xFFE6E8D5)),
  heritage(
    '人文古蹟',
    Icons.account_balance_outlined,
    Color(0xFF8A6320),
    Color(0xFFF0E5CC),
  ),
  urban('城市地標', Icons.apartment_outlined, Color(0xFF44597A), Color(0xFFDFE4EC)),
  coast('海岸水域', Icons.waves_outlined, Color(0xFF2F6566), Color(0xFFD9E7E4)),
  sacred(
    '信仰聖地',
    Icons.menu_book_outlined,
    Color(0xFF6E4A63),
    Color(0xFFECDCE6),
  );

  const JournalCategory(this.label, this.icon, this.ink, this.bg);

  /// Localised display label.
  final String label;

  /// Glyph shown in tags and placeholder thumbs.
  final IconData icon;

  /// Foreground (text/icon) colour.
  final Color ink;

  /// Background fill colour.
  final Color bg;
}
