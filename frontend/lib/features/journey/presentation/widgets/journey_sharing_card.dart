import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A beautiful sharing card that renders a Journey entry as a
/// passport-style card suitable for social media sharing.
///
/// This widget is rendered off-screen via [RepaintBoundary] and
/// captured as an image by [JourneySharingService].
class JourneySharingCard extends StatelessWidget {
  final String placeName;
  final String placeAddress;
  final String narrationExcerpt;
  final DateTime visitedAt;
  final String? imageUrl;
  final Uint8List? imageBytes;

  const JourneySharingCard({
    super.key,
    required this.placeName,
    required this.placeAddress,
    required this.narrationExcerpt,
    required this.visitedAt,
    this.imageUrl,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1923), Color(0xFF1A2B3D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            imageUrl: imageUrl,
            imageBytes: imageBytes,
            placeName: placeName,
          ),
          _CardBody(
            placeName: placeName,
            placeAddress: placeAddress,
            narrationExcerpt: narrationExcerpt,
            visitedAt: visitedAt,
          ),
          const _CardFooter(),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String placeName;

  const _CardHeader({
    required this.imageUrl,
    required this.imageBytes,
    required this.placeName,
  });

  bool get _hasImage =>
      (imageUrl != null && imageUrl!.isNotEmpty) || imageBytes != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      return _PlaceholderHeader(placeName: placeName);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            // Gradient overlay for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0F1923)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // Stamp badge
            const Positioned(top: 16, right: 16, child: _StampBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      cacheManager: PlaceImageCacheManager.instance,
      placeholder: (_, __) => Container(color: const Color(0xFF1A2B3D)),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF1A2B3D),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white38),
        ),
      ),
    );
  }
}

class _PlaceholderHeader extends StatelessWidget {
  final String placeName;

  const _PlaceholderHeader({required this.placeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF137fec), Color(0xFF0D5BB5)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.explore,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          const Positioned(top: 16, right: 16, child: _StampBadge()),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampBadge extends StatelessWidget {
  const _StampBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40137fec),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            'share_card.visited'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final String placeName;
  final String placeAddress;
  final String narrationExcerpt;
  final DateTime visitedAt;

  const _CardBody({
    required this.placeName,
    required this.placeAddress,
    required this.narrationExcerpt,
    required this.visitedAt,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy.MM.dd').format(visitedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Place name
          Text(
            placeName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),

          if (placeAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    placeAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Narration excerpt
          Text(
            narrationExcerpt,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.7,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // App icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Icon(Icons.explore, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'app.name'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'app.tagline'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'share_card.explore_more'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
