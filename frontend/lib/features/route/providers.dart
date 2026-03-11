import 'package:context_app/features/route/data/route_ai_service.dart';
import 'package:context_app/features/route/domain/use_cases/create_route_use_case.dart';
import 'package:context_app/features/route/presentation/controllers/route_controller.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RouteAiService Provider
final routeAiServiceProvider = Provider<RouteAiService>((ref) {
  return GeminiRouteAiService();
});

/// CreateRouteUseCase Provider
final createRouteUseCaseProvider = Provider<CreateRouteUseCase>((ref) {
  final aiService = ref.watch(routeAiServiceProvider);
  final usageRepository = ref.watch(usageRepositoryProvider);
  return CreateRouteUseCase(aiService, usageRepository);
});

/// RouteController Provider
///
/// 不使用 autoDispose，因為使用者會在路線畫面和導覽畫面間切換
final routeControllerProvider =
    StateNotifierProvider<RouteController, RouteState>((ref) {
      final useCase = ref.watch(createRouteUseCaseProvider);
      return RouteController(useCase);
    });
