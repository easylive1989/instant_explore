import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';

/// Serialises [Place] to/from a plain JSON map for local persistence.
class PlaceJsonMapper {
  static Map<String, dynamic> toJson(Place p) => {
    'id': p.id,
    'name': p.name,
    'formattedAddress': p.formattedAddress,
    'location': {
      'latitude': p.location.latitude,
      'longitude': p.location.longitude,
    },
    'types': p.types,
    'photos': p.photos
        .map(
          (photo) => {
            'url': photo.url,
            'widthPx': photo.widthPx,
            'heightPx': photo.heightPx,
            'authorAttributions': photo.authorAttributions,
          },
        )
        .toList(),
    'category': p.category.name,
  };

  static Place fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>;
    final photos = (json['photos'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (p) => PlacePhoto(
            url: p['url'] as String,
            widthPx: (p['widthPx'] as num?)?.toInt() ?? 0,
            heightPx: (p['heightPx'] as num?)?.toInt() ?? 0,
            authorAttributions: (p['authorAttributions'] as List? ?? [])
                .cast<String>(),
          ),
        )
        .toList();

    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      formattedAddress: json['formattedAddress'] as String? ?? '',
      location: PlaceLocation(
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
      ),
      types: (json['types'] as List? ?? []).cast<String>(),
      photos: photos,
      category: PlaceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PlaceCategory.modernUrban,
      ),
    );
  }
}
