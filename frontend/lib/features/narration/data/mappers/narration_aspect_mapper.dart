import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

/// NarrationAspect 的資料轉換器
///
/// 委派至 [NarrationAspect.key] 和 [NarrationAspect.fromKey]，
/// 保留此類別以維持 data 層既有的 Mapper 慣例。
class NarrationAspectMapper {
  /// 從字串解析
  static NarrationAspect? fromString(String value) =>
      NarrationAspect.fromKey(value);

  /// 轉換為 API 字串
  static String toApiString(NarrationAspect aspect) => aspect.key;
}
