import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/camera/data/image_analysis_service.dart';
import 'package:context_app/features/camera/domain/use_cases/analyze_image_use_case.dart';
import 'package:context_app/features/camera/presentation/camera_controller.dart';

/// 圖片分析服務 Provider
final imageAnalysisServiceProvider = Provider<ImageAnalysisService>((ref) {
  return ImageAnalysisService();
});

/// 分析圖片用例 Provider
final analyzeImageUseCaseProvider = Provider<AnalyzeImageUseCase>((ref) {
  final service = ref.watch(imageAnalysisServiceProvider);
  return AnalyzeImageUseCase(service);
});

/// 相機控制器 Provider
final cameraControllerProvider =
    StateNotifierProvider<CameraController, CameraState>((ref) {
      return CameraController();
    });
