import 'package:context_app/features/explore/domain/models/place_category.dart';

/// PlaceCategory 的資料轉換器
class PlaceCategoryMapper {
  /// 從字串解析
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
}
