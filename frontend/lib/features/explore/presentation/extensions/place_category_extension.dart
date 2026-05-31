import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/shared/widgets/journal/journal_category.dart';

extension PlaceCategoryUIExtension on PlaceCategory {
  /// Maps the domain taxonomy onto the Field Journal visual category used by
  /// [CategoryTag] and [GlyphThumb].
  ///
  /// The journal palette only defines five families, so museum and food
  /// places fall back to their nearest visual neighbour (heritage / urban).
  JournalCategory get journalCategory {
    switch (this) {
      case PlaceCategory.historicalCultural:
      case PlaceCategory.museumArt:
        return JournalCategory.heritage;
      case PlaceCategory.naturalLandscape:
        return JournalCategory.nature;
      case PlaceCategory.modernUrban:
      case PlaceCategory.foodMarket:
        return JournalCategory.urban;
    }
  }
}
