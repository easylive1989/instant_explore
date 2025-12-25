import 'dart:convert';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:http/http.dart' as http;
import 'package:context_app/features/explore/domain/models/place.dart';

class PlacesApiService {
  final String _apiKey;
  static const String _baseUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const String _textSearchUrl =
      'https://places.googleapis.com/v1/places:searchText';

  /// Basic FieldMask - 不含 rating 和 priceLevel (Pro 等級，較便宜)
  static const String _basicFieldMask =
      'places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos';

  PlacesApiService(this._apiKey);

  Future<List<Place>> searchByText(String query, {String? languageCode}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API Key is not configured.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': _basicFieldMask,
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

  /// 搜尋附近地點（基礎版，不含 rating 和 priceLevel）
  /// 用於列表頁，降低 API 成本
  Future<List<Place>> searchNearby(
    PlaceLocation location, {
    int maxResultCount = 20,
    required double radius,
    List<String>? includedTypes,
    String? languageCode,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API Key is not configured.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': _basicFieldMask,
    };

    final Map<String, dynamic> requestBody = {
      'maxResultCount': maxResultCount,
      'rankPreference': 'DISTANCE',
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
