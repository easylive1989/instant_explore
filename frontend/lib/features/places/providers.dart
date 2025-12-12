import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/places/application/get_current_location_use_case.dart';
import 'package:context_app/features/places/domain/services/location_service.dart';
import 'package:context_app/features/places/infrastructure/geolocator_service.dart';
import 'package:context_app/features/places/models/place.dart';

// Infrastructure Providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorService();
});

// Use Case Providers
final getCurrentLocationUseCaseProvider = Provider<GetCurrentLocationUseCase>((
  ref,
) {
  final locationService = ref.watch(locationServiceProvider);
  return GetCurrentLocationUseCase(locationService);
});

// UI-facing Providers
final currentLocationProvider = FutureProvider<PlaceLocation>((ref) async {
  final useCase = ref.watch(getCurrentLocationUseCaseProvider);
  return useCase.execute();
});
