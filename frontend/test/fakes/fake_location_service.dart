import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';

/// Fake [LocationService] that returns a fixed location without touching GPS.
class FakeLocationService implements LocationService {
  final PlaceLocation location;
  final Exception? error;

  FakeLocationService({
    this.location = const PlaceLocation(latitude: 25.0, longitude: 121.0),
    this.error,
  });

  @override
  Future<PlaceLocation> getCurrentLocation() async {
    if (error != null) throw error!;
    return location;
  }
}
