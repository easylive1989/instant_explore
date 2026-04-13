import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:context_app/features/camera/data/image_analysis_service.dart';
import 'package:context_app/features/camera/domain/services/image_analysis_service.dart';
import 'package:context_app/features/camera/domain/use_cases/analyze_image_use_case.dart';
import 'package:context_app/features/camera/presentation/controllers/camera_controller.dart';

/// 圖片分析服務 Provider（domain 介面，data 層實作）
final imageAnalysisServiceProvider = Provider<ImageAnalysisService>((ref) {
  return FirebaseImageAnalysisService();
});

/// 分析圖片用例 Provider
final analyzeImageUseCaseProvider = Provider<AnalyzeImageUseCase>((ref) {
  final service = ref.watch(imageAnalysisServiceProvider);
  return AnalyzeImageUseCase(service, () => const Uuid().v4());
});

/// 相機控制器 Provider
final cameraControllerProvider =
    StateNotifierProvider<CameraController, CameraState>((ref) {
      return CameraController();
    });
