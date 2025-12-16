import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:context_app/features/explore/domain/models/place.dart';

class PlacesApiService {
  final String _apiKey;
  static const String _baseUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const String _textSearchUrl =
      'https://places.googleapis.com/v1/places:searchText';

  PlacesApiService(this._apiKey);

  Future<List<Place>> searchByText(String query, {String? languageCode}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API Key is not configured.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.types,places.photos',
    };

    final Map<String, dynamic> requestBody = {'textQuery': query};
    if (languageCode != null) {
      requestBody['languageCode'] = languageCode;
    }

    final body = jsonEncode(requestBody);

    final response = await http.post(
      Uri.parse(_textSearchUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final placesJson = data['places'] as List?;
      if (placesJson != null) {
        return placesJson
            .map((placeJson) => Place.fromJson(placeJson))
            .toList();
      }
      return [];
    } else {
      throw Exception(
        'Failed to search places: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Place>> searchNearby(
    PlaceLocation location, {
    int maxResultCount = 10,
    double radius = 1000.0,
    List<String>? includedTypes,
    String? languageCode,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API Key is not configured.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.types,places.photos',
    };

    final Map<String, dynamic> requestBody = {
      'maxResultCount': maxResultCount,
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius,
        },
      },
    };

    if (includedTypes != null && includedTypes.isNotEmpty) {
      requestBody['includedTypes'] = includedTypes;
    }
    if (languageCode != null) {
      requestBody['languageCode'] = languageCode;
    }

    final body = jsonEncode(requestBody);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final placesJson = data['places'] as List?;
      if (placesJson != null) {
        return placesJson
            .map((placeJson) => Place.fromJson(placeJson))
            .toList();
      }
      return [];
    } else {
      throw Exception(
        'Failed to load nearby places: ${response.statusCode} ${response.body}',
      );
    }
  }
}
