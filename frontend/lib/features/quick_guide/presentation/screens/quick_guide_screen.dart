import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/ads/presentation/widgets/watch_ad_dialog.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/quick_guide/presentation/controllers/quick_guide_controller.dart';
import 'package:context_app/features/quick_guide/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Quick Guide tab screen.
///
/// Lets the user take or choose a photo, then shows an AI-generated
/// description and an option to save the entry to their journey.
class QuickGuideScreen extends ConsumerStatefulWidget {
  const QuickGuideScreen({super.key});

  @override
  ConsumerState<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends ConsumerState<QuickGuideScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quickGuideControllerProvider.notifier).reset();
    });
    super.dispose();
  }

  Future<void> _navigateToPlayer(
    BuildContext context,
    String description,
  ) async {
    final language = _currentLanguage();

    final NarrationContent content;
    try {
      content = NarrationContent.create(description, language: language);
    } catch (_) {
      return;
    }

    final place = Place(
      id: 'quick-guide-${DateTime.now().millisecondsSinceEpoch}',
      name: 'quick_guide.title'.tr(),
      formattedAddress: '',
      location: const PlaceLocation(latitude: 0, longitude: 0),
      types: const [],
      photos: const [],
      category: PlaceCategory.modernUrban,
    );

    await context.push<void>(
      '/player',
      extra: {'place': place, 'narrationContent': content, 'autoPlay': true},
    );
  }

  Future<void> _handleQuotaExceeded(BuildContext context) async {
    ref.read(quickGuideControllerProvider.notifier).reset();
    final result = await showWatchAdDialog(context, ref);
    if (result == 'subscribe' && context.mounted) {
      context.pushNamed('subscription');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final locale =
        EasyLocalization.of(context)?.locale.toLanguageTag() ?? 'zh-TW';
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final mimeType = _mimeType(image.path);

      await ref
          .read(quickGuideControllerProvider.notifier)
          .analyzeImage(
            imageBytes: bytes,
            mimeType: mimeType,
            language: locale,
          );
    } catch (e) {
      debugPrint('Error picking image: $e');
      ref.read(quickGuideControllerProvider.notifier).reset();
    }
  }

  Language _currentLanguage() {
    final locale = EasyLocalization.of(context)?.locale;
    return locale?.languageCode == 'zh'
        ? Language.traditionalChinese
        : Language.english;
  }

  String _mimeType(String path) {
    switch (path.split('.').last.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    ref.listen<QuickGuideState>(quickGuideControllerProvider, (
      previous,
      current,
    ) {
      if (previous?.isSuccess != true &&
          current.isSuccess &&
          current.aiDescription != null) {
        final description = current.aiDescription!;
        ref.read(quickGuideControllerProvider.notifier).reset();
        _navigateToPlayer(context, description);
      }
      if (previous?.isQuotaExceeded != true && current.isQuotaExceeded) {
        _handleQuotaExceeded(context);
      }
    });

    final guideState = ref.watch(quickGuideControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'quick_guide.title'.tr(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            Expanded(
              child: guideState.imageBytes == null
                  ? _ImageSourceSelector(
                      onPickImage: (source) async {
                        final usageStatus = await ref
                            .read(usageRepositoryProvider)
                            .getUsageStatus();
                        if (!context.mounted) return;
                        if (!usageStatus.canUseNarration) {
                          final result = await showWatchAdDialog(context, ref);
                          if (result == 'subscribe') {
                            if (!context.mounted) return;
                            context.pushNamed('subscription');
                          }
                          return;
                        }
                        _pickImage(source);
                      },
                    )
                  : _CaptureResultView(
                      guideState: guideState,
                      onRetake: () => ref
                          .read(quickGuideControllerProvider.notifier)
                          .reset(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceSelector extends StatelessWidget {
  final Future<void> Function(ImageSource) onPickImage;

  const _ImageSourceSelector({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'quick_guide.instruction'.tr(),
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'quick_guide.instruction_subtitle'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onPickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 24),
                label: Text(
                  'quick_guide.take_photo'.tr(),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onPickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 24),
                label: Text(
                  'quick_guide.from_gallery'.tr(),
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
}

class _CaptureResultView extends StatelessWidget {
  final QuickGuideState guideState;
  final VoidCallback onRetake;

  const _CaptureResultView({required this.guideState, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image preview
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                    guideState.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 24,
                child: GestureDetector(
                  onTap: onRetake,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Description area
        Expanded(flex: 3, child: _DescriptionArea(state: guideState)),
      ],
    );
  }
}

class _DescriptionArea extends StatelessWidget {
  final QuickGuideState state;

  const _DescriptionArea({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.isSuccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'quick_guide.analyzing'.tr(),
              style: const TextStyle(
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
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'quick_guide.analysis_error'.tr(),
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
