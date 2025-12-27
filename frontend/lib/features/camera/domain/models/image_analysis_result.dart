import 'package:context_app/features/explore/domain/models/place_category.dart';

/// 圖片分析結果模型
///
/// 代表 AI 分析圖片後的結果
class ImageAnalysisResult {
  /// 識別的名稱（景點或食物名稱）
  final String name;

  /// 簡短描述
  final String description;

  /// 分類
  final PlaceCategory category;

  /// 可能的地址（如有）
  final String? address;

  /// 額外的類型標籤
  final List<String> types;

  const ImageAnalysisResult({
    required this.name,
    required this.description,
    required this.category,
    this.address,
    this.types = const [],
  });
}
