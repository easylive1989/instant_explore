import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/data/route_ai_service.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:context_app/features/usage/domain/errors/usage_error.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';

/// 建立路線規劃用例
///
/// 職責：
/// - 檢查每日使用額度
/// - 呼叫 RouteAiService 取得路線規劃
/// - 成功後消耗使用額度
///
/// 錯誤處理：
/// - AppError(UsageError.dailyQuotaExceeded): 每日額度已用完
/// - AppError(RouteError.*): AI 服務相關錯誤（透傳自 Service）
class CreateRouteUseCase {
  final RouteAiService _routeAiService;
  final UsageRepository _usageRepository;

  CreateRouteUseCase(this._routeAiService, this._usageRepository);

  /// 執行用例：生成路線規劃
  ///
  /// [candidatePlaces] 候選景點列表
  /// [userLocation] 使用者目前位置
  /// [language] 語言代碼
  ///
  /// 成功後消耗 1 次額度，失敗不消耗
  Future<TourRoute> execute({
    required List<Place> candidatePlaces,
    required PlaceLocation userLocation,
    required String language,
  }) async {
    // 1. 檢查每日使用額度
    final usageStatus = await _usageRepository.getUsageStatus();
    if (!usageStatus.canUseNarration) {
      throw const AppError(type: UsageError.dailyQuotaExceeded);
    }

    // 2. 呼叫 AI 服務生成路線
    // AppError 會直接透傳給上層
    final route = await _routeAiService.generateRoute(
      candidatePlaces: candidatePlaces,
      userLocation: userLocation,
      language: language,
    );

    // 3. 成功後消耗一次使用額度
    await _usageRepository.consumeUsage();

    return route;
  }
}
