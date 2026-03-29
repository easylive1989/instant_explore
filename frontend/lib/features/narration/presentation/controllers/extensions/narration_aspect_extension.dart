import 'package:flutter/material.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

extension NarrationAspectUI on NarrationAspect {
  /// 取得 i18n 翻譯鍵
  String get translationKey {
    switch (this) {
      case NarrationAspect.historicalBackground:
        return 'narration_aspect.historical_background';
      case NarrationAspect.architecture:
        return 'narration_aspect.architecture';
      case NarrationAspect.customs:
        return 'narration_aspect.customs';
      case NarrationAspect.geology:
        return 'narration_aspect.geology';
      case NarrationAspect.myths:
        return 'narration_aspect.myths';
    }
  }

  /// 取得描述翻譯鍵
  String get descriptionKey {
    switch (this) {
      case NarrationAspect.historicalBackground:
        return 'narration_aspect.historical_background_description';
      case NarrationAspect.architecture:
        return 'narration_aspect.architecture_description';
      case NarrationAspect.customs:
        return 'narration_aspect.customs_description';
      case NarrationAspect.geology:
        return 'narration_aspect.geology_description';
      case NarrationAspect.myths:
        return 'narration_aspect.myths_description';
    }
  }

  /// 取得圖標
  IconData get icon {
    switch (this) {
      case NarrationAspect.historicalBackground:
        return Icons.history_edu;
      case NarrationAspect.architecture:
        return Icons.architecture;
      case NarrationAspect.customs:
        return Icons.people;
      case NarrationAspect.geology:
        return Icons.layers;
      case NarrationAspect.myths:
        return Icons.auto_stories;
    }
  }
}
