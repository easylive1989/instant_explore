import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/core/utils/geo_utils.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/data/route_prompt_builder.dart';
import 'package:context_app/features/route/domain/errors/route_error.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

/// 路線規劃 AI 服務介面
abstract class RouteAiService {
  /// 從候選景點中生成路線規劃
  Future<TourRoute> generateRoute({
    required List<Place> candidatePlaces,
    required PlaceLocation userLocation,
    required String language,
  });
}

/// 使用 Gemini 實作的路線規劃 AI 服務
class GeminiRouteAiService implements RouteAiService {
  @override
  Future<TourRoute> generateRoute({
    required List<Place> candidatePlaces,
    required PlaceLocation userLocation,
    required String language,
  }) async {
    try {
      final promptBuilder = RoutePromptBuilder(
        candidatePlaces: candidatePlaces,
        userLocation: userLocation,
        language: language,
      );
      final prompt = promptBuilder.build();

      final ai = FirebaseAI.vertexAI();
      final model = ai.generativeModel(model: 'gemini-2.5-flash');

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      return parseRouteResponse(responseText, candidatePlaces);
    } on AppError {
      rethrow;
    } on FirebaseException catch (e, stackTrace) {
      throw AppError(
        type: RouteError.networkError,
        message: 'Firebase 伺服器錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on SocketException catch (e, stackTrace) {
      throw AppError(
        type: RouteError.networkError,
        message: '網路連線失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    } on TimeoutException catch (e, stackTrace) {
      throw AppError(
        type: RouteError.networkError,
        message: '連線逾時',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 解析 AI 回傳的 JSON 為 TourRoute
  ///
  /// 此方法為 visible for testing
  TourRoute parseRouteResponse(
    String responseText,
    List<Place> candidatePlaces,
  ) {
    final jsonString = _stripCodeFences(responseText);

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      throw AppError(
        type: RouteError.aiParsingFailed,
        message: 'AI 回傳格式無法解析',
        originalException: e,
        stackTrace: stackTrace,
      );
    }

    final title = json['title'] as String? ?? '';
    final stopsJson = json['stops'] as List<dynamic>? ?? [];

    if (stopsJson.isEmpty) {
      throw const AppError(
        type: RouteError.aiParsingFailed,
        message: 'AI 未回傳任何景點',
      );
    }

    // 將 candidatePlaces 建成 map 方便查找
    final placesMap = {for (final p in candidatePlaces) p.id: p};

    final stops = <RouteStop>[];
    for (final stopJson in stopsJson) {
      final map = stopJson as Map<String, dynamic>;
      final placeId = map['placeId'] as String?;
      final overview = map['overview'] as String?;

      if (placeId == null || !placesMap.containsKey(placeId)) {
        throw AppError(
          type: RouteError.invalidPlaceId,
          message: 'AI 回傳的景點 ID 不在候選清單中: $placeId',
        );
      }

      stops.add(RouteStop(place: placesMap[placeId]!, overview: overview));
    }

    // 計算站間距離和步行時間
    final stopsWithDistances = _calculateStopDistances(stops);

    return TourRoute(title: title, stops: stopsWithDistances);
  }

  /// 移除 markdown code fence（如 ```json ... ```）
  String _stripCodeFences(String text) {
    final trimmed = text.trim();

    // 處理 ```json ... ``` 或 ``` ... ```
    final codeFenceRegex = RegExp(
      r'^```(?:json)?\s*\n?(.*?)\n?\s*```$',
      dotAll: true,
    );
    final match = codeFenceRegex.firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return trimmed;
  }

  /// 計算各站之間的距離和步行時間
  List<RouteStop> _calculateStopDistances(List<RouteStop> stops) {
    final result = <RouteStop>[];

    for (var i = 0; i < stops.length; i++) {
      if (i < stops.length - 1) {
        final from = stops[i].place.location;
        final to = stops[i + 1].place.location;
        final distance = calculateHaversineDistance(from, to);
        final walkingTime = estimateWalkingMinutes(from, to);
        result.add(
          stops[i].copyWith(
            distanceToNext: distance,
            walkingTimeToNext: walkingTime,
          ),
        );
      } else {
        // 最後一站無下一站
        result.add(stops[i]);
      }
    }

    return result;
  }
}
