import 'package:context_app/features/explore/data/dto/google_place_photo_dto.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';

/// Google Places API Place DTO
///
/// 用於解析 Google Places API 回傳的地點資料
class GooglePlaceDto {
  final String id;
  final dynamic displayName;
  final String? formattedAddress;
  final Map<String, dynamic>? location;
  final double? rating;
  final List<dynamic>? types;
  final List<GooglePlacePhotoDto> photos;

  GooglePlaceDto({
    required this.id,
    required this.displayName,
    this.formattedAddress,
    this.location,
    this.rating,
    this.types,
    required this.photos,
  });

  factory GooglePlaceDto.fromJson(Map<String, dynamic> json) {
    return GooglePlaceDto(
      id: json['id'] ?? '',
      displayName: json['displayName'],
      formattedAddress: json['formattedAddress'],
      location: json['location'],
      rating: json['rating']?.toDouble(),
      types: json['types'],
      photos:
          (json['photos'] as List?)
              ?.map((photo) => GooglePlacePhotoDto.fromJson(photo))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'formattedAddress': formattedAddress,
      'location': location,
      'rating': rating,
      'types': types,
      'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  /// 轉換為 Domain Model
  ///
  /// [apiKey] 用於產生照片 URL
  /// [maxPhotoWidth] 照片最大寬度
  Place toDomain({required String apiKey, int maxPhotoWidth = 400}) {
    final extractedTypes = _extractTypes(types);
    final category = PlaceCategory.fromPlaceTypes(extractedTypes);

    return Place(
      id: id,
      name: _extractDisplayName(displayName) ?? '',
      formattedAddress: formattedAddress ?? '',
      location: PlaceLocation.fromJson(location ?? {}),
      rating: rating,
      types: extractedTypes,
      photos: photos
          .map(
            (photoDto) => PlacePhoto(
              url: photoDto.toPhotoUrl(maxWidth: maxPhotoWidth, apiKey: apiKey),
              widthPx: photoDto.widthPx,
              heightPx: photoDto.heightPx,
              authorAttributions: photoDto.authorAttributions,
            ),
          )
          .toList(),
      category: category,
    );
  }

  String? _extractDisplayName(dynamic displayName) {
    if (displayName == null) return null;
    if (displayName is String) return displayName;
    if (displayName is Map<String, dynamic>) {
      final text = displayName['text'];
      if (text != null) return text.toString();
    }
    return displayName.toString();
  }

  List<String> _extractTypes(dynamic types) {
    if (types == null) return [];
    if (types is List) {
      return types.map((type) => type.toString()).toList();
    }
    return [];
  }
}
