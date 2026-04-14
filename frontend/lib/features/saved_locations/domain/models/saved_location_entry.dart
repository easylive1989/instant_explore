import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:equatable/equatable.dart';

/// A location saved by the user for later narration.
///
/// Stores the full [Place] data so it can be passed directly
/// to the narration config screen.
class SavedLocationEntry extends Equatable {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingCount;
  final List<String> types;
  final List<Map<String, dynamic>> photosJson;
  final String categoryKey;
  final DateTime savedAt;

  const SavedLocationEntry({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingCount,
    required this.types,
    required this.photosJson,
    required this.categoryKey,
    required this.savedAt,
  });

  /// Creates from a [Place] domain model.
  factory SavedLocationEntry.fromPlace(Place place) {
    return SavedLocationEntry(
      placeId: place.id,
      name: place.name,
      formattedAddress: place.formattedAddress,
      latitude: place.location.latitude,
      longitude: place.location.longitude,
      rating: place.rating,
      userRatingCount: place.userRatingCount,
      types: place.types,
      photosJson: place.photos
          .map((p) => {
                'url': p.url,
                'width_px': p.widthPx,
                'height_px': p.heightPx,
                'author_attributions': p.authorAttributions,
              })
          .toList(),
      categoryKey: place.category.name,
      savedAt: DateTime.now(),
    );
  }

  /// Reconstructs the [Place] domain model.
  Place toPlace() {
    final photos = photosJson
        .map((p) => PlacePhoto(
              url: p['url'] as String,
              widthPx: p['width_px'] as int,
              heightPx: p['height_px'] as int,
              authorAttributions:
                  (p['author_attributions'] as List<dynamic>).cast<String>(),
            ))
        .toList();

    return Place(
      id: placeId,
      name: name,
      formattedAddress: formattedAddress,
      location: PlaceLocation(
        latitude: latitude,
        longitude: longitude,
      ),
      rating: rating,
      userRatingCount: userRatingCount,
      types: types,
      photos: photos,
      category: PlaceCategory.values.firstWhere(
        (c) => c.name == categoryKey,
        orElse: () => PlaceCategory.modernUrban,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'name': name,
        'formatted_address': formattedAddress,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'user_rating_count': userRatingCount,
        'types': types,
        'photos': photosJson,
        'category_key': categoryKey,
        'saved_at': savedAt.toIso8601String(),
      };

  factory SavedLocationEntry.fromJson(Map<String, dynamic> json) {
    return SavedLocationEntry(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      formattedAddress: json['formatted_address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['user_rating_count'] as int?,
      types: (json['types'] as List<dynamic>).cast<String>(),
      photosJson: (json['photos'] as List<dynamic>)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(),
      categoryKey: json['category_key'] as String,
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  @override
  List<Object?> get props => [placeId];
}
