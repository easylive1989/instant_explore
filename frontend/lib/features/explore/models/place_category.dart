enum PlaceCategory {
  historicalCultural,
  naturalLandscapes,
  modernLandmarks,
  museumsArts,
  localFood,
  other; // Fallback

  String get translationKey {
    switch (this) {
      case PlaceCategory.historicalCultural:
        return 'category.historical_cultural';
      case PlaceCategory.naturalLandscapes:
        return 'category.natural_landscapes';
      case PlaceCategory.modernLandmarks:
        return 'category.modern_landmarks';
      case PlaceCategory.museumsArts:
        return 'category.museums_arts';
      case PlaceCategory.localFood:
        return 'category.local_food';
      case PlaceCategory.other:
        return 'category.other';
    }
  }
}
