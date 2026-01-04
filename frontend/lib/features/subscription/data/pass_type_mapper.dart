import 'package:context_app/features/subscription/domain/models/pass_type.dart';

/// PassType 資料層映射工具
///
/// 提供 PassType 與外部資料格式之間的轉換
class PassTypeMapper {
  /// 根據產品 ID 取得對應的 PassType
  static PassType? fromProductId(String productId) {
    for (final type in PassType.values) {
      if (type.productId == productId) {
        return type;
      }
    }
    return null;
  }
}
