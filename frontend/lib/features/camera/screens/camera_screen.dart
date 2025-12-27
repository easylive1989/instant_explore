import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/camera/providers.dart';
import 'package:context_app/features/camera/presentation/camera_controller.dart';
import 'package:context_app/features/camera/widgets/analysis_result_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// 相機畫面
///
/// 讓使用者拍照或選擇圖片，進行 AI 分析
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _displayImage;

  @override
  void dispose() {
    // 離開畫面時重置狀態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).reset();
    });
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final mimeType = _getMimeType(image.path);

      setState(() {
        _displayImage = bytes;
      });

      // 設定圖片並開始分析
      ref.read(cameraControllerProvider.notifier).setImage(bytes);
      await _analyzeImage(bytes, mimeType);
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

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'camera.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_displayImage != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
            Icon(
              Icons.camera_alt_rounded,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'camera.instruction'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'camera.instruction_subtitle'.tr(),
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // 拍照按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 24),
                label: Text(
                  'camera.take_photo'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 從相簿選擇
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 24),
                label: Text(
                  'camera.from_gallery'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'camera.analyzing'.tr(),
              style: TextStyle(
                color: AppColors.textSecondaryDark,
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
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retake,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToNarration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'camera.start_narration'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
