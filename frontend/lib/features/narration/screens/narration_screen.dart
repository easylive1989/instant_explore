import 'package:context_app/core/config/app_colors.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:context_app/core/widgets/ai_over_limit_dialog.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/narration/widgets/narration_transcript_area.dart';
import 'package:context_app/features/narration/widgets/narration_control_panel.dart';

class NarrationScreen extends ConsumerStatefulWidget {
  final Place place;
  final NarrationAspect narrationAspect;
  final String? initialContent;
  final bool enableSave;
  final String? language; // 語言參數（可選）

  const NarrationScreen({
    super.key,
    required this.place,
    required this.narrationAspect,
    this.initialContent,
    this.enableSave = true,
    this.language,
  });

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen> {
  final AutoScrollController _scrollController = AutoScrollController();
  int? _lastSegmentIndex;

  @override
  void initState() {
    super.initState();
    // 初始化播放器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 使用傳入的語言（來自 JourneyEntry），若無則使用當前應用語言
      final locale =
          widget.language ??
          easy.EasyLocalization.of(context)?.locale.toLanguageTag() ??
          'zh-TW';

      if (widget.initialContent != null) {
        ref
            .read(playerControllerProvider.notifier)
            .initializeWithContent(
              widget.place,
              widget.narrationAspect,
              widget.initialContent!,
              language: locale,
            );
      } else {
        ref
            .read(playerControllerProvider.notifier)
            .initialize(widget.place, widget.narrationAspect, language: locale);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 自動滾動到當前播放的段落
  void _scrollToCurrentSegment(int? segmentIndex) {
    if (segmentIndex == null ||
        segmentIndex == _lastSegmentIndex ||
        !_scrollController.hasClients) {
      return;
    }

    _lastSegmentIndex = segmentIndex;

    // 使用 scrollToIndex 滑動到指定段落（定位到螢幕頂部）
    _scrollController.scrollToIndex(
      segmentIndex + 1, // +1 因為 index 0 是頂部空白項
      preferPosition: AutoScrollPosition.middle, // 定位到螢幕頂部
      duration: const Duration(milliseconds: 300),
    );
  }

  /// 顯示 AI 超限對話框
  void _showAiOverLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AiOverLimitDialog(),
    ).then((_) {
      // 對話框關閉後，導航回 config screen
      if (mounted) {
        context.pushReplacementNamed('config', extra: widget.place);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 監聽錯誤狀態並顯示對應的對話框
    ref.listen(playerControllerProvider, (previous, current) {
      // 當狀態從非錯誤變為錯誤時，且需要特殊對話框
      if ((previous == null || !previous.hasError) &&
          current.hasError &&
          current.errorType != null &&
          current.errorType!.requiresSpecialDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showAiOverLimitDialog();
        });
      }

      // 監聽當前段落索引變化並自動滾動
      final previousIndex = previous?.currentSegmentIndex;
      final currentIndex = current.currentSegmentIndex;
      if (previousIndex != currentIndex && currentIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToCurrentSegment(currentIndex);
        });
      }
    });

    // Colors from design
    const primaryColor = AppColors.primary;
    const backgroundColor = AppColors.backgroundDark;
    const surfaceColor = AppColors.surfaceDarkPlayer;
    const primaryColorShadow = Color(0x4D137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => context.go('/'),
                        ),
                        Expanded(
                          child: Text(
                            widget.place.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Transcript Area
                  Expanded(
                    child: NarrationTranscriptArea(
                      scrollController: _scrollController,
                      backgroundColor: backgroundColor,
                      primaryColor: primaryColor,
                      place: widget.place,
                      narrationAspect: widget.narrationAspect,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          NarrationControlPanel(
            place: widget.place,
            primaryColor: primaryColor,
            primaryColorShadow: primaryColorShadow,
            surfaceColor: surfaceColor,
            backgroundColor: backgroundColor,
            enableSave: widget.enableSave,
          ),
        ],
      ),
    );
  }
}
