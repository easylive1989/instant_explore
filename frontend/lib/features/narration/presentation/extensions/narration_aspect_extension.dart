import 'package:flutter/material.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

extension NarrationAspectUI on NarrationAspect {
  /// 取得 i18n 翻譯鍵
  String get translationKey {
    switch (this) {
      // 人文古蹟類
      case NarrationAspect.historicalBackground:
        return 'narration_aspect.historical_background';
      case NarrationAspect.architecture:
        return 'narration_aspect.architecture';
      case NarrationAspect.customs:
        return 'narration_aspect.customs';
      case NarrationAspect.relevance:
        return 'narration_aspect.relevance';
      // 自然景觀類
      case NarrationAspect.geology:
        return 'narration_aspect.geology';
      case NarrationAspect.photoSpots:
        return 'narration_aspect.photo_spots';
      case NarrationAspect.floraFauna:
        return 'narration_aspect.flora_fauna';
      case NarrationAspect.myths:
        return 'narration_aspect.myths';
      // 現代地標與城市類
      case NarrationAspect.designConcept:
        return 'narration_aspect.design_concept';
      case NarrationAspect.statistics:
        return 'narration_aspect.statistics';
      case NarrationAspect.status:
        return 'narration_aspect.status';
      case NarrationAspect.lifestyle:
        return 'narration_aspect.lifestyle';
      // 博物館與藝術展覽類
      case NarrationAspect.highlights:
        return 'narration_aspect.highlights';
      case NarrationAspect.emotion:
        return 'narration_aspect.emotion';
      case NarrationAspect.guidance:
        return 'narration_aspect.guidance';
      case NarrationAspect.context:
        return 'narration_aspect.context';
      // 在地美食與夜市類
      case NarrationAspect.ingredients:
        return 'narration_aspect.ingredients';
      case NarrationAspect.etiquette:
        return 'narration_aspect.etiquette';
      case NarrationAspect.brandStory:
        return 'narration_aspect.brand_story';
      case NarrationAspect.sensory:
        return 'narration_aspect.sensory';
    }
  }

  /// 取得描述翻譯鍵
  String get descriptionKey {
    switch (this) {
      // 人文古蹟類
      case NarrationAspect.historicalBackground:
        return 'narration_aspect.historical_background_description';
      case NarrationAspect.architecture:
        return 'narration_aspect.architecture_description';
      case NarrationAspect.customs:
        return 'narration_aspect.customs_description';
      case NarrationAspect.relevance:
        return 'narration_aspect.relevance_description';
      // 自然景觀類
      case NarrationAspect.geology:
        return 'narration_aspect.geology_description';
      case NarrationAspect.photoSpots:
        return 'narration_aspect.photo_spots_description';
      case NarrationAspect.floraFauna:
        return 'narration_aspect.flora_fauna_description';
      case NarrationAspect.myths:
        return 'narration_aspect.myths_description';
      // 現代地標與城市類
      case NarrationAspect.designConcept:
        return 'narration_aspect.design_concept_description';
      case NarrationAspect.statistics:
        return 'narration_aspect.statistics_description';
      case NarrationAspect.status:
        return 'narration_aspect.status_description';
      case NarrationAspect.lifestyle:
        return 'narration_aspect.lifestyle_description';
      // 博物館與藝術展覽類
      case NarrationAspect.highlights:
        return 'narration_aspect.highlights_description';
      case NarrationAspect.emotion:
        return 'narration_aspect.emotion_description';
      case NarrationAspect.guidance:
        return 'narration_aspect.guidance_description';
      case NarrationAspect.context:
        return 'narration_aspect.context_description';
      // 在地美食與夜市類
      case NarrationAspect.ingredients:
        return 'narration_aspect.ingredients_description';
      case NarrationAspect.etiquette:
        return 'narration_aspect.etiquette_description';
      case NarrationAspect.brandStory:
        return 'narration_aspect.brand_story_description';
      case NarrationAspect.sensory:
        return 'narration_aspect.sensory_description';
    }
  }

  /// 取得圖標
  IconData get icon {
    switch (this) {
      // 人文古蹟類
      case NarrationAspect.historicalBackground:
        return Icons.history_edu;
      case NarrationAspect.architecture:
        return Icons.architecture;
      case NarrationAspect.customs:
        return Icons.people;
      case NarrationAspect.relevance:
        return Icons.timeline;
      // 自然景觀類
      case NarrationAspect.geology:
        return Icons.layers;
      case NarrationAspect.photoSpots:
        return Icons.camera_alt;
      case NarrationAspect.floraFauna:
        return Icons.pets;
      case NarrationAspect.myths:
        return Icons.auto_stories;
      // 現代地標與城市類
      case NarrationAspect.designConcept:
        return Icons.design_services;
      case NarrationAspect.statistics:
        return Icons.bar_chart;
      case NarrationAspect.status:
        return Icons.stars;
      case NarrationAspect.lifestyle:
        return Icons.shopping_bag;
      // 博物館與藝術展覽類
      case NarrationAspect.highlights:
        return Icons.star;
      case NarrationAspect.emotion:
        return Icons.favorite;
      case NarrationAspect.guidance:
        return Icons.visibility;
      case NarrationAspect.context:
        return Icons.category;
      // 在地美食與夜市類
      case NarrationAspect.ingredients:
        return Icons.eco;
      case NarrationAspect.etiquette:
        return Icons.restaurant_menu;
      case NarrationAspect.brandStory:
        return Icons.store;
      case NarrationAspect.sensory:
        return Icons.settings_voice;
    }
  }
}
