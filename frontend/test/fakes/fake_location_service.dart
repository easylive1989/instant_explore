import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';

/// Fake [LocationService] that returns a fixed location without touching GPS.
///
/// [error] 可注入任意物件（含 `LocationError`）讓 [getCurrentLocation] throw。
class FakeLocationService implements LocationService {
  final PlaceLocation location;
  final Object? error;

  /// [requestPermission] 的回傳值（模擬使用者是否在系統對話框授權）。
  final bool grantOnRequest;

  int requestPermissionCallCount = 0;
  int openAppSettingsCallCount = 0;
  int openLocationSettingsCallCount = 0;
  int getCurrentLocationCallCount = 0;

  FakeLocationService({
    this.location = const PlaceLocation(latitude: 25.0, longitude: 121.0),
    this.error,
    this.grantOnRequest = true,
  });

  @override
  Future<PlaceLocation> getCurrentLocation() async {
    getCurrentLocationCallCount += 1;
    if (error != null) throw error!;
    return location;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount += 1;
    return grantOnRequest;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCallCount += 1;
  }

  @override
  Future<void> openLocationSettings() async {
    openLocationSettingsCallCount += 1;
  }
}
