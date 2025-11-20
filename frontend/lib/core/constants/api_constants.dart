/// API-related constant values.
///
/// Contains API endpoints, configuration, and related constants.
class ApiConstants {
  ApiConstants._();

  /// Google Places API constants
  static const String googlePlacesApiBaseUrl =
      'https://maps.googleapis.com/maps/api';
  static const String placesNearbySearchEndpoint = '/place/nearbysearch/json';
  static const String placesDetailsEndpoint = '/place/details/json';
  static const String placesPhotoEndpoint = '/place/photo';

  /// Google Places search types
  static const String placeTypeRestaurant = 'restaurant';
  static const String placeTypeCafe = 'cafe';
  static const String placeTypeBar = 'bar';
  static const String placeTypeFood = 'food';

  /// Google Places search radius (meters)
  static const int defaultSearchRadius = 5000;
  static const int minSearchRadius = 100;
  static const int maxSearchRadius = 50000;

  /// Google Places API response limits
  static const int maxPlacesResults = 20;

  /// Photo size constraints
  static const int maxPhotoWidth = 400;
  static const int maxPhotoHeight = 400;

  /// API timeouts (milliseconds)
  static const int defaultTimeout = 30000;
  static const int uploadTimeout = 60000;

  /// Retry configuration
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;

  /// HTTP status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusInternalServerError = 500;
}
