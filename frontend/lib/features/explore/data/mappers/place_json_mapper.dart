import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';

/// Serialises [Place] to/from a plain JSON map for local persistence.
class PlaceJsonMapper {
  static Map<String, dynamic> toJson(Place p) => {
    'id': p.id,
    'name': p.name,
    'address': p.address,
    'location': {
      'latitude': p.location.latitude,
      'longitude': p.location.longitude,
    },
    'tags': p.tags,
    'photos': p.photos
        .map(
          (photo) => {
            'url': photo.url,
            'width': photo.width,
            'height': photo.height,
            'attributions': photo.attributions,
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
            width: (p['width'] as num?)?.toInt() ?? 0,
            height: (p['height'] as num?)?.toInt() ?? 0,
            attributions: (p['attributions'] as List? ?? []).cast<String>(),
          ),
        )
        .toList();

    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      location: PlaceLocation(
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
      ),
      tags: (json['tags'] as List? ?? []).cast<String>(),
      photos: photos,
      category: PlaceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PlaceCategory.modernUrban,
      ),
    );
  }
}
