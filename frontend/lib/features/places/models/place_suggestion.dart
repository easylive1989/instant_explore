import 'package:flutter/foundation.dart';

/// 地點自動完成建議
@immutable
class PlaceSuggestion {
  final String placeId;
  final String text;
  final String? secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.text,
    this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final placePrediction = json['placePrediction'];
    if (placePrediction == null) {
      throw const FormatException('Missing placePrediction in suggestion');
    }

    final textData = placePrediction['text'];
    final structuredFormat = placePrediction['structuredFormat'];

    return PlaceSuggestion(
      placeId: placePrediction['placeId'] as String,
      text: textData?['text'] as String? ?? '',
      secondaryText: structuredFormat?['secondaryText']?['text'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceSuggestion &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;
}
