import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:context_app/features/explore/data/dto/google_place_dto.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:http/http.dart' as http;

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

  String get apiKey => _apiKey;

  Future<List<GooglePlaceDto>> searchByText(
    String query, {
    String? languageCode,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw const AppError(
          type: PlaceError.configurationError,
          message: 'Google Maps API Key 未配置',
        );
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
              .map((placeJson) => GooglePlaceDto.fromJson(placeJson))
              .toList();
        }
        return [];
      } else {
        throw AppError(
          type: PlaceError.searchFailed,
          message: '搜尋地點失敗',
          context: {
            'status_code': response.statusCode,
            'response_body': response.body,
          },
        );
      }
    } on SocketException catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.networkError,
        message: '網路連線失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.networkError,
        message: '連線逾時',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      throw AppError(
        type: PlaceError.unknown,
        message: '發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<GooglePlaceDto>> searchNearby(
    PlaceLocation location, {
    int maxResultCount = 20,
    required double radius,
    List<String>? includedTypes,
    String? languageCode,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw const AppError(
          type: PlaceError.configurationError,
          message: 'Google Maps API Key 未配置',
          context: {'raw_message': 'Google Maps API Key is not configured.'},
        );
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
              .map((placeJson) => GooglePlaceDto.fromJson(placeJson))
              .toList();
        }
        return [];
      } else {
        throw AppError(
          type: PlaceError.searchFailed,
          message: '載入附近地點失敗',
          context: {
            'status_code': response.statusCode,
            'response_body': response.body,
          },
        );
      }
    } on SocketException catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.networkError,
        message: '網路連線失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.networkError,
        message: '連線逾時',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      throw AppError(
        type: PlaceError.unknown,
        message: '發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
}
