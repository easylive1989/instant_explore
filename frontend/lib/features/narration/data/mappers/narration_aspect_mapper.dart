import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

/// NarrationAspect 的資料轉換器
///
/// 委派至 [NarrationAspect.key] 和 [NarrationAspect.fromKey]，
/// 保留此類別以維持 data 層既有的 Mapper 慣例。
class NarrationAspectMapper {
  /// 從字串解析單一面向
  static NarrationAspect? fromString(String value) =>
      NarrationAspect.fromKey(value);

  /// 轉換單一面向為 API 字串
  static String toApiString(NarrationAspect aspect) => aspect.key;

  /// 從字串列表解析多個面向
  static Set<NarrationAspect> fromStringList(List<String> values) =>
      values.map(NarrationAspect.fromKey).whereType<NarrationAspect>().toSet();

  /// 轉換多個面向為 API 字串列表
  static List<String> toApiStringList(Set<NarrationAspect> aspects) =>
      aspects.map((a) => a.key).toList();
}
