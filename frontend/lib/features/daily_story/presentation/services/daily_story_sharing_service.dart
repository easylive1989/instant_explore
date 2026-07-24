import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/services/daily_story_share_url.dart';
import 'package:context_app/features/daily_story/presentation/widgets/daily_story_sharing_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger('DailyStorySharingService');

/// Captures a [DailyStorySharingCard] as a PNG and shares it via the
/// platform share sheet, with the story's canonical URL in the text.
class DailyStorySharingService {
  DailyStorySharingService._();

  /// Renders the [story] as a share card off-screen, captures a PNG,
  /// and opens the system share sheet with the story URL in the text.
  static Future<void> shareStoryCard({
    required BuildContext context,
    required DailyStory story,
    VoidCallback? onSheetPresented,
  }) async {
    try {
      final pngBytes = await _captureCardImage(context: context, story: story);
      if (pngBytes == null) {
        _log.warning('Failed to capture daily story card image');
        onSheetPresented?.call();
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/daily_story_card_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      final url = buildDailyStoryShareUrl(story);
      final shareText = '${'share_card.story_share_text'.tr()}\n$url';

      onSheetPresented?.call();
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], text: shareText);
    } catch (e, stack) {
      _log.severe('Error sharing daily story card', e, stack);
      onSheetPresented?.call();
    }
  }

  static String _titleFor(DailyStory story) =>
      story.cardTitle ?? story.placeName;

  static String _hookFor(DailyStory story) =>
      story.cardPullQuote ?? story.cardTitleSub ?? _firstSentence(story.story);

  static String _firstSentence(String text) {
    final trimmed = text.trim();
    final end = trimmed.indexOf(RegExp(r'[。.!?！？]'));
    if (end == -1) return trimmed;
    return trimmed.substring(0, end + 1);
  }

  /// Renders the card widget off-screen and captures it as PNG bytes.
  static Future<Uint8List?> _captureCardImage({
    required BuildContext context,
    required DailyStory story,
  }) async {
    final key = GlobalKey();

    final widget = RepaintBoundary(
      key: key,
      child: MediaQuery(
        data: MediaQuery.of(context),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Localizations.override(
            context: context,
            child: Material(
              color: Colors.transparent,
              child: DailyStorySharingCard(
                title: _titleFor(story),
                hook: _hookFor(story),
                placeName: story.placeName,
                placeLocation: story.placeLocation,
                era: story.era,
                imageUrl: story.imageUrl,
              ),
            ),
          ),
        ),
      ),
    );

    // Build the widget in an overlay so it renders off-screen.
    final overlay = OverlayEntry(
      builder: (_) => Positioned(left: -1000, top: -1000, child: widget),
    );

    final overlayState = Overlay.of(context);
    overlayState.insert(overlay);

    // Wait for the widget tree and any image loading to settle.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      overlay.remove();
    }
  }
}
