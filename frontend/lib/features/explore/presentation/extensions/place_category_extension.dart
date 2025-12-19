import 'package:flutter/material.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

extension PlaceCategoryUIExtension on PlaceCategory {
  /// 取得 i18n 翻譯鍵
  String get translationKey {
    switch (this) {
      case PlaceCategory.historicalCultural:
        return 'place_category.historical_cultural';
      case PlaceCategory.naturalLandscape:
        return 'place_category.natural_landscape';
      case PlaceCategory.modernUrban:
        return 'place_category.modern_urban';
      case PlaceCategory.museumArt:
        return 'place_category.museum_art';
      case PlaceCategory.foodMarket:
        return 'place_category.food_market';
    }
  }

  /// 取得描述翻譯鍵
  String get descriptionKey {
    switch (this) {
      case PlaceCategory.historicalCultural:
        return 'place_category.historical_cultural_description';
      case PlaceCategory.naturalLandscape:
        return 'place_category.natural_landscape_description';
      case PlaceCategory.modernUrban:
        return 'place_category.modern_urban_description';
      case PlaceCategory.museumArt:
        return 'place_category.museum_art_description';
      case PlaceCategory.foodMarket:
        return 'place_category.food_market_description';
    }
  }

  /// 取得圖標
  IconData get icon {
    switch (this) {
      case PlaceCategory.historicalCultural:
        return Icons.temple_buddhist;
      case PlaceCategory.naturalLandscape:
        return Icons.landscape;
      case PlaceCategory.modernUrban:
        return Icons.location_city;
      case PlaceCategory.museumArt:
        return Icons.museum;
      case PlaceCategory.foodMarket:
        return Icons.restaurant;
    }
  }

  /// 取得顏色
  Color get color {
    switch (this) {
      case PlaceCategory.historicalCultural:
        return const Color(0xFFD4A574); // 古銅色
      case PlaceCategory.naturalLandscape:
        return const Color(0xFF4CAF50); // 綠色
      case PlaceCategory.modernUrban:
        return const Color(0xFF2196F3); // 藍色
      case PlaceCategory.museumArt:
        return const Color(0xFF9C27B0); // 紫色
      case PlaceCategory.foodMarket:
        return const Color(0xFFFF9800); // 橘色
    }
  }
}
