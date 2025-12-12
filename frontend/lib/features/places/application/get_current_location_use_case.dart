import 'package:context_app/features/places/domain/services/location_service.dart';
import 'package:context_app/features/places/models/place.dart';

class GetCurrentLocationUseCase {
  final LocationService _locationService;

  GetCurrentLocationUseCase(this._locationService);

  Future<PlaceLocation> execute() async {
    // In a real app, you might have more complex logic here,
    // like checking user permissions, fetching from cache, etc.
    try {
      return await _locationService.getCurrentLocation();
    } catch (e) {
      // Handle or rethrow domain-specific exceptions
      rethrow;
    }
  }
}
