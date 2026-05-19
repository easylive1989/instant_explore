import 'package:context_app/core/utils/geo_utils.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Result of [SearchNearbyPlacesUseCase.execute].
typedef NearbyPlacesResult = ({List<Place> places, PlaceLocation userLocation});

class SearchNearbyPlacesUseCase {
  final LocationService _locationService;
  final PlacesRepository _placesRepository;

  static const double _defaultRadius = 1000.0;

  SearchNearbyPlacesUseCase(this._locationService, this._placesRepository);

  Future<NearbyPlacesResult> execute({
    required Language language,
    double radius = _defaultRadius,
  }) async {
    final userLocation = await _locationService.getCurrentLocation();

    final places = await _placesRepository.getNearbyPlaces(
      userLocation,
      language: language,
      radius: radius,
    );

    return (
      places: _sortByDistance(places, userLocation),
      userLocation: userLocation,
    );
  }

  List<Place> _sortByDistance(List<Place> places, PlaceLocation userLocation) {
    final withDistance = places.map((place) {
      final distance = calculateHaversineDistance(
        fromLatitude: userLocation.latitude,
        fromLongitude: userLocation.longitude,
        toLatitude: place.location.latitude,
        toLongitude: place.location.longitude,
      );
      return _PlaceWithDistance(place: place, distance: distance);
    }).toList()..sort((a, b) => a.distance.compareTo(b.distance));

    return withDistance.map((p) => p.place).toList();
  }
}

class _PlaceWithDistance {
  final Place place;
  final double distance;

  _PlaceWithDistance({required this.place, required this.distance});
}
