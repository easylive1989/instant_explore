import 'dart:convert';
import 'dart:typed_data';

import 'package:context_app/features/settings/domain/models/language.dart';

/// A journey entry created from a quick photo guide session.
///
/// Stores the captured image and the AI-generated description.
class QuickGuideEntry {
  final String id;
  final Uint8List imageBytes;
  final String aiDescription;
  final DateTime createdAt;
  final Language language;

  const QuickGuideEntry({
    required this.id,
    required this.imageBytes,
    required this.aiDescription,
    required this.createdAt,
    required this.language,
  });

  /// Creates a new entry with the given [id] and current timestamp.
  ///
  /// [id] 由呼叫端產生，domain 層不負責 ID 生成策略。
  factory QuickGuideEntry.create({
    required String id,
    required Uint8List imageBytes,
    required String aiDescription,
    required Language language,
  }) {
    return QuickGuideEntry(
      id: id,
      imageBytes: imageBytes,
      aiDescription: aiDescription,
      createdAt: DateTime.now(),
      language: language,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'image_base64': base64Encode(imageBytes),
    'ai_description': aiDescription,
    'created_at': createdAt.toIso8601String(),
    'language': language.code,
  };

  factory QuickGuideEntry.fromJson(Map<String, dynamic> json) {
    return QuickGuideEntry(
      id: json['id'] as String,
      imageBytes: base64Decode(json['image_base64'] as String),
      aiDescription: json['ai_description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: Language(json['language'] as String? ?? 'zh-TW'),
    );
  }
}
