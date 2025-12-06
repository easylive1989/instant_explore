import 'package:flutter/foundation.dart';

/// Represents the data required for displaying a diary entry in a list/card.
/// This is a view-specific model to decouple widgets from data services.
@immutable
class DiaryEntryViewData {
  final String id;
  final DateTime visitDate;
  final String? placeName;
  final String? imageUrl;

  const DiaryEntryViewData({
    required this.id,
    required this.visitDate,
    this.placeName,
    this.imageUrl,
  });
}
