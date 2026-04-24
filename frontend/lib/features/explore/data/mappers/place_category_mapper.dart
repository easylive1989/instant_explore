import 'package:context_app/features/explore/domain/models/place_category.dart';

/// Resolves a snake_case category string to a [PlaceCategory] value.
///
/// Used by the camera feature when the AI service returns a category name
/// (e.g. `'historical_cultural'`). Falls back to [PlaceCategory.modernUrban]
/// for unknown values.
class PlaceCategoryMapper {
  static PlaceCategory fromString(String value) {
    switch (value) {
      case 'historical_cultural':
        return PlaceCategory.historicalCultural;
      case 'natural_landscape':
        return PlaceCategory.naturalLandscape;
      case 'modern_urban':
        return PlaceCategory.modernUrban;
      case 'museum_art':
        return PlaceCategory.museumArt;
      case 'food_market':
        return PlaceCategory.foodMarket;
      default:
        return PlaceCategory.modernUrban;
    }
  }
}
