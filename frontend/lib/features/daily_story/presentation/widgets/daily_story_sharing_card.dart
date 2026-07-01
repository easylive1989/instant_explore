import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_reader_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A shareable card that renders a daily story in the warm "paper"
/// reader aesthetic, suitable for social sharing.
///
/// Rendered off-screen via [RepaintBoundary] and captured to PNG by
/// [DailyStorySharingService]. Colours are fixed [CardReaderTheme]
/// literals so the captured image looks identical across platforms and
/// appearance settings.
class DailyStorySharingCard extends StatelessWidget {
  final String title;
  final String hook;
  final String placeName;
  final String placeLocation;
  final String era;
  final String? imageUrl;
  final Uint8List? imageBytes;

  const DailyStorySharingCard({
    super.key,
    required this.title,
    required this.hook,
    required this.placeName,
    required this.placeLocation,
    required this.era,
    this.imageUrl,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: CardReaderTheme.readBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(imageUrl: imageUrl, imageBytes: imageBytes),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSerifTc(
                    color: CardReaderTheme.readInk,
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hook,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerifTc(
                    color: CardReaderTheme.readDim,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const _Hairline(),
          _Footer(placeName: placeName, placeLocation: placeLocation, era: era),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  const _Header({this.imageUrl, this.imageBytes});

  bool get _hasImage =>
      imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _hasImage
          ? (imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _Placeholder(),
                  ))
          : const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CardReaderTheme.inkBg,
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_stories_outlined,
        color: CardReaderTheme.clay,
        size: 48,
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 1,
      color: CardReaderTheme.readLine,
    );
  }
}

class _Footer extends StatelessWidget {
  final String placeName;
  final String placeLocation;
  final String era;
  const _Footer({
    required this.placeName,
    required this.placeLocation,
    required this.era,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$placeName · $placeLocation · $era',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CardReaderTheme.readCap,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LORESCAPE',
            style: GoogleFonts.notoSerifTc(
              color: CardReaderTheme.readCap,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
