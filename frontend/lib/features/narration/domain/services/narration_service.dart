import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/grounding_info.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Result of a narration generation call.
///
/// [text] is the model's generated narration script.
/// [grounding] is the Google Search grounding snapshot when the
/// model grounded its answer; `null` otherwise.
typedef NarrationGenerationResult = ({String text, GroundingInfo? grounding});

abstract class NarrationService {
  /// 生成導覽內容文本
  ///
  /// [place] 地點資訊
  /// [aspects] 導覽介紹面向（支援多選）
  /// [language] 語言
  /// 返回生成的導覽文本與（若有）grounding metadata
  /// 拋出 NarrationServiceException 如果服務呼叫失敗
  Future<NarrationGenerationResult> generateNarration({
    required Place place,
    required Set<NarrationAspect> aspects,
    required Language language,
  });
}
