import 'place.dart';
import 'place_photo.dart';

/// Google Places API 地點詳細資訊模型
///
/// 用於儲存從 Place Details API 回傳的詳細地點資訊
class PlaceDetails extends Place {
  final String? nationalPhoneNumber;
  final String? googleMapsUri;
  final OpeningHours? openingHours;
  final List<Review> reviews;
  final String? editorialSummary;

  PlaceDetails({
    required super.id,
    required super.name,
    required super.formattedAddress,
    required super.location,
    super.rating,
    super.priceLevel,
    required super.types,
    required super.photos,
    super.internationalPhoneNumber,
    super.websiteUri,
    super.currentOpeningHours,
    this.nationalPhoneNumber,
    this.googleMapsUri,
    this.openingHours,
    required this.reviews,
    this.editorialSummary,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      id: json['id'] ?? '',
      name: _extractDisplayName(json['displayName']) ?? json['name'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      location: PlaceLocation.fromJson(json['location'] ?? {}),
      rating: json['rating']?.toDouble(),
      priceLevel: _parsePriceLevel(json['priceLevel']),
      types: _extractTypes(json['types']),
      photos:
          (json['photos'] as List?)
              ?.map((photo) => PlacePhoto.fromJson(photo))
              .toList() ??
          [],
      internationalPhoneNumber: json['internationalPhoneNumber'],
      websiteUri: json['websiteUri'],
      currentOpeningHours: json['currentOpeningHours']?['openNow'],
      nationalPhoneNumber: json['nationalPhoneNumber'],
      googleMapsUri: json['googleMapsUri'],
      openingHours: json['currentOpeningHours'] != null
          ? OpeningHours.fromJson(json['currentOpeningHours'])
          : null,
      reviews:
          (json['reviews'] as List?)
              ?.map((review) => Review.fromJson(review))
              .toList() ??
          [],
      editorialSummary: json['editorialSummary']?['text'],
    );
  }

  /// 提取顯示名稱
  static String? _extractDisplayName(dynamic displayName) {
    if (displayName == null) return null;
    if (displayName is String) return displayName;
    if (displayName is Map<String, dynamic>) {
      return displayName['text']?.toString();
    }
    return displayName.toString();
  }

  /// 提取地點類型
  static List<String> _extractTypes(dynamic types) {
    if (types == null) return [];
    if (types is List) {
      return types.map((type) => type.toString()).toList();
    }
    return [];
  }

  /// 解析價格等級
  static int? _parsePriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return null;
    if (priceLevel is String) {
      switch (priceLevel) {
        case 'PRICE_LEVEL_FREE':
          return 0;
        case 'PRICE_LEVEL_INEXPENSIVE':
          return 1;
        case 'PRICE_LEVEL_MODERATE':
          return 2;
        case 'PRICE_LEVEL_EXPENSIVE':
          return 3;
        case 'PRICE_LEVEL_VERY_EXPENSIVE':
          return 4;
        default:
          return null;
      }
    }
    return priceLevel is int ? priceLevel : null;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'nationalPhoneNumber': nationalPhoneNumber,
      'googleMapsUri': googleMapsUri,
      'openingHours': openingHours?.toJson(),
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'editorialSummary': editorialSummary,
    });
    return json;
  }

  /// 取得營業狀態文字
  String get openingStatusText {
    if (openingHours == null) return '營業時間未知';
    return openingHours!.openNow ? '營業中' : '已打烊';
  }

  /// 取得今天的營業時間
  String? get todayOpeningHours {
    return openingHours?.todayHours;
  }
}

/// 營業時間資料模型
class OpeningHours {
  final bool openNow;
  final List<String> weekdayText;

  OpeningHours({required this.openNow, required this.weekdayText});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['openNow'] ?? false,
      weekdayText: List<String>.from(json['weekdayText'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'openNow': openNow, 'weekdayText': weekdayText};
  }

  /// 取得今天的營業時間
  String? get todayHours {
    if (weekdayText.isEmpty) return null;
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // Monday is 0 in weekdayText
    if (todayIndex < weekdayText.length) {
      return weekdayText[todayIndex];
    }
    return null;
  }
}

/// 評論資料模型
class Review {
  final String authorName;
  final String? authorPhotoUri;
  final int rating;
  final String text;
  final DateTime publishTime;

  Review({
    required this.authorName,
    this.authorPhotoUri,
    required this.rating,
    required this.text,
    required this.publishTime,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName:
          json['authorAttribution']?['displayName'] ??
          json['authorName'] ??
          '匿名用戶',
      authorPhotoUri: json['authorAttribution']?['photoUri'],
      rating: json['rating'] ?? 0,
      text: json['text']?['text'] ?? json['text'] ?? '',
      publishTime:
          DateTime.tryParse(json['publishTime'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorName': authorName,
      'authorPhotoUri': authorPhotoUri,
      'rating': rating,
      'text': text,
      'publishTime': publishTime.toIso8601String(),
    };
  }

  /// 取得評分星級文字
  String get ratingStars {
    return '⭐' * rating;
  }

  /// 取得相對發布時間
  String get relativePublishTime {
    final now = DateTime.now();
    final difference = now.difference(publishTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years 年前';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months 個月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else {
      return '剛剛';
    }
  }
}
