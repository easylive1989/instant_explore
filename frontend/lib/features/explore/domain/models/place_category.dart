import 'package:flutter/material.dart';

/// 景點類型分類
///
/// 用於將 Google Places API 的原始類型對應到五種主要景點類型
enum PlaceCategory {
  /// 人文古蹟類 (Historical & Cultural Sites)
  /// 如：寺廟、古城、皇宮、故居
  historicalCultural,

  /// 自然景觀類 (Natural Landscapes)
  /// 如：高山、湖泊、峽谷、國家公園
  naturalLandscape,

  /// 現代地標與城市類 (Modern Landmarks & Urban)
  /// 如：摩天大樓、購物區、地標建築
  modernUrban,

  /// 博物館與藝術展覽類 (Museums & Arts)
  /// 如：博物館、美術館、畫廊
  museumArt,

  /// 在地美食與夜市類 (Local Food & Night Markets)
  /// 如：夜市、美食街、特色餐廳
  foodMarket;

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

  /// 從 Google Places API 的類型列表推斷景點類型
  ///
  /// 根據 types 欄位中的關鍵字來判斷景點類型
  static PlaceCategory fromPlaceTypes(List<String> types) {
    // 轉換為小寫以便匹配
    final lowerTypes = types.map((t) => t.toLowerCase()).toList();

    // 人文古蹟類關鍵字
    const historicalKeywords = [
      'church',
      'temple',
      'mosque',
      'synagogue',
      'hindu_temple',
      'place_of_worship',
      'historical_landmark',
      'monument',
      'castle',
      'palace',
      'fort',
      'archaeological_site',
      'heritage_site',
      'shrine',
      'cemetery',
    ];

    // 自然景觀類關鍵字
    const naturalKeywords = [
      'park',
      'natural_feature',
      'mountain',
      'lake',
      'beach',
      'waterfall',
      'forest',
      'canyon',
      'valley',
      'river',
      'hiking_area',
      'national_park',
      'nature_reserve',
      'botanical_garden',
      'zoo',
      'aquarium',
    ];

    // 現代地標與城市類關鍵字
    const modernKeywords = [
      'landmark',
      'tourist_attraction',
      'point_of_interest',
      'skyscraper',
      'observation_deck',
      'shopping_mall',
      'department_store',
      'city_hall',
      'convention_center',
      'stadium',
      'airport',
      'train_station',
      'subway_station',
      'bridge',
      'tower',
    ];

    // 博物館與藝術展覽類關鍵字
    const museumKeywords = [
      'museum',
      'art_gallery',
      'gallery',
      'exhibition',
      'cultural_center',
      'library',
      'theater',
      'performing_arts_theater',
      'concert_hall',
      'opera_house',
    ];

    // 在地美食與夜市類關鍵字
    const foodKeywords = [
      'restaurant',
      'food',
      'cafe',
      'bar',
      'night_club',
      'meal_takeaway',
      'meal_delivery',
      'bakery',
      'supermarket',
      'grocery',
      'liquor_store',
      'market',
      'night_market',
      'food_court',
    ];

    // 依優先順序檢查（越具體的類型優先）
    // 1. 博物館與藝術（較具體）
    if (lowerTypes.any((type) => museumKeywords.contains(type))) {
      return PlaceCategory.museumArt;
    }

    // 2. 在地美食與夜市
    if (lowerTypes.any((type) => foodKeywords.contains(type))) {
      return PlaceCategory.foodMarket;
    }

    // 3. 人文古蹟（較具體）
    if (lowerTypes.any((type) => historicalKeywords.contains(type))) {
      return PlaceCategory.historicalCultural;
    }

    // 4. 自然景觀
    if (lowerTypes.any((type) => naturalKeywords.contains(type))) {
      return PlaceCategory.naturalLandscape;
    }

    // 5. 現代地標與城市（最廣泛，作為預設）
    if (lowerTypes.any((type) => modernKeywords.contains(type))) {
      return PlaceCategory.modernUrban;
    }

    // 如果都不符合，預設為現代地標與城市類
    return PlaceCategory.modernUrban;
  }

  /// 從字串解析
  static PlaceCategory? fromString(String value) {
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
        return null;
    }
  }

  /// 轉換為 API 字串
  String toApiString() {
    switch (this) {
      case PlaceCategory.historicalCultural:
        return 'historical_cultural';
      case PlaceCategory.naturalLandscape:
        return 'natural_landscape';
      case PlaceCategory.modernUrban:
        return 'modern_urban';
      case PlaceCategory.museumArt:
        return 'museum_art';
      case PlaceCategory.foodMarket:
        return 'food_market';
    }
  }
}
