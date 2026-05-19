import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/core/services/image_picker_service.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:context_app/features/camera/presentation/controllers/camera_controller.dart';
import 'package:context_app/features/camera/presentation/widgets/analysis_result_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';

/// 相機畫面
///
/// 讓使用者拍照或選擇圖片，進行 AI 分析
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  Uint8List? _displayImage;
  late final CameraController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(cameraControllerProvider.notifier);
  }

  @override
  void dispose() {
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.reset();
    });
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ref
          .read(imagePickerServiceProvider)
          .pickImage(source);

      if (picked == null) return;

      setState(() {
        _displayImage = picked.bytes;
      });

      // 設定圖片並開始分析
      ref.read(cameraControllerProvider.notifier).setImage(picked.bytes);
      await _analyzeImage(picked.bytes, picked.mimeType);
    } catch (e) {
      debugPrint('Error picking image: $e');
      ref.read(cameraControllerProvider.notifier).setError(e.toString());
    }
  }

  Future<void> _analyzeImage(Uint8List bytes, String mimeType) async {
    final controller = ref.read(cameraControllerProvider.notifier);
    final useCase = ref.read(analyzeImageUseCaseProvider);

    controller.startAnalyzing();

    try {
      final locale =
          EasyLocalization.of(context)?.locale.toLanguageTag() ?? 'zh-TW';

      final place = await useCase.execute(
        imageBytes: bytes,
        mimeType: mimeType,
        language: locale,
      );

      controller.setResult(place);
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      controller.setError('camera.analysis_error'.tr());
    }
  }

  void _navigateToNarration() {
    final state = ref.read(cameraControllerProvider);
    if (state.place != null && _displayImage != null) {
      context.pushNamed(
        'config',
        extra: {'place': state.place, 'capturedImageBytes': _displayImage},
      );
    }
  }

  void _retake() {
    setState(() {
      _displayImage = null;
    });
    ref.read(cameraControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AdaptiveIconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'camera.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_displayImage != null)
            AdaptiveIconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retake,
            ),
        ],
      ),
      body: _buildBody(cameraState),
    );
  }

  Widget _buildBody(CameraState state) {
    // 如果還沒選擇圖片，顯示選擇選項
    if (_displayImage == null) {
      return _buildImageSourceSelector();
    }

    // 顯示圖片和分析結果
    return Column(
      children: [
        // 圖片預覽
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _displayImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink(key: Key('camera.image_error')),
              ),
            ),
          ),
        ),

        // 分析結果或載入中
        Expanded(flex: 2, child: _buildResultArea(state)),
      ],
    );
  }

  Widget _buildImageSourceSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 說明文字
            Image.asset(
              'assets/images/camera/camera_icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'camera.instruction'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'camera.instruction_subtitle'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            AdaptiveButton(
              expanded: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              icon: const Icon(Icons.camera_alt, size: 24),
              onPressed: () => _pickImage(ImageSource.camera),
              child: Text(
                'camera.take_photo'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AdaptiveButton(
              expanded: true,
              style: AdaptiveButtonStyle.outlined,
              padding: const EdgeInsets.symmetric(vertical: 16),
              icon: const Icon(Icons.photo_library, size: 24),
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text(
                'camera.from_gallery'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea(CameraState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AdaptiveProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'camera.analyzing'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'camera.analysis_error'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AdaptiveButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _retake,
              child: Text('camera.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state.isSuccess && state.place != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnalysisResultCard(place: state.place!),
          const SizedBox(height: 16),
          // 開始導覽按鈕（放在卡片外面）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdaptiveButton(
              expanded: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              onPressed: _navigateToNarration,
              child: Text(
                'camera.start_narration'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
