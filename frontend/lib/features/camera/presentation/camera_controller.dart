import 'dart:typed_data';

import 'package:context_app/features/camera/domain/models/image_analysis_result.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 相機狀態
enum CameraStatus {
  /// 閒置中
  idle,

  /// 正在擷取圖片
  capturing,

  /// 正在分析圖片
  analyzing,

  /// 分析成功
  success,

  /// 發生錯誤
  error,
}

/// 相機狀態模型
class CameraState {
  final CameraStatus status;
  final Uint8List? imageBytes;
  final ImageAnalysisResult? analysisResult;
  final Place? place;
  final String? errorMessage;

  const CameraState({
    this.status = CameraStatus.idle,
    this.imageBytes,
    this.analysisResult,
    this.place,
    this.errorMessage,
  });

  CameraState copyWith({
    CameraStatus? status,
    Uint8List? imageBytes,
    ImageAnalysisResult? analysisResult,
    Place? place,
    String? errorMessage,
  }) {
    return CameraState(
      status: status ?? this.status,
      imageBytes: imageBytes ?? this.imageBytes,
      analysisResult: analysisResult ?? this.analysisResult,
      place: place ?? this.place,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 是否正在載入中
  bool get isLoading =>
      status == CameraStatus.capturing || status == CameraStatus.analyzing;

  /// 是否有錯誤
  bool get hasError => status == CameraStatus.error;

  /// 是否分析成功
  bool get isSuccess => status == CameraStatus.success;
}

/// 相機控制器
class CameraController extends StateNotifier<CameraState> {
  CameraController() : super(const CameraState());

  /// 設定擷取的圖片
  void setImage(Uint8List imageBytes) {
    state = state.copyWith(
      status: CameraStatus.capturing,
      imageBytes: imageBytes,
    );
  }

  /// 開始分析
  void startAnalyzing() {
    state = state.copyWith(status: CameraStatus.analyzing);
  }

  /// 設定分析結果
  void setResult(Place place) {
    state = state.copyWith(status: CameraStatus.success, place: place);
  }

  /// 設定錯誤
  void setError(String message) {
    state = state.copyWith(status: CameraStatus.error, errorMessage: message);
  }

  /// 重置狀態
  void reset() {
    state = const CameraState();
  }
}
