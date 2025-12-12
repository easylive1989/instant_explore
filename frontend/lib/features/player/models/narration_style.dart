import 'package:flutter/material.dart';

/// 導覽風格值對象
///
/// 代表用戶選擇的導覽深度偏好
enum NarrationStyle {
  /// 簡要版 (~30秒)
  brief,

  /// 深度版 (~10分鐘)
  deepDive;

  /// 取得 i18n 翻譯鍵
  String get translationKey {
    switch (this) {
      case NarrationStyle.brief:
        return 'narration_style.brief';
      case NarrationStyle.deepDive:
        return 'narration_style.deep_dive';
    }
  }

  /// 取得描述翻譯鍵
  String get descriptionKey {
    switch (this) {
      case NarrationStyle.brief:
        return 'narration_style.brief_description';
      case NarrationStyle.deepDive:
        return 'narration_style.deep_dive_description';
    }
  }

  /// 取得圖標
  IconData get icon {
    switch (this) {
      case NarrationStyle.brief:
        return Icons.bolt;
      case NarrationStyle.deepDive:
        return Icons.headphones;
    }
  }

  /// 從字串解析
  static NarrationStyle? fromString(String value) {
    switch (value) {
      case 'brief':
        return NarrationStyle.brief;
      case 'deep_dive':
        return NarrationStyle.deepDive;
      default:
        return null;
    }
  }

  /// 轉換為 API 字串
  String toApiString() {
    switch (this) {
      case NarrationStyle.brief:
        return 'brief';
      case NarrationStyle.deepDive:
        return 'deep_dive';
    }
  }
}
