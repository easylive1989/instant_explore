import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/explore/data/services/wikimedia_image_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wikimedia 圖片服務 Provider
final wikimediaImageServiceProvider = Provider<WikimediaImageService>((ref) {
  return WikimediaImageService();
});

/// 地點圖片快取 Provider
///
/// 使用 FutureProvider.family 來快取每個地點的圖片 URL 搜尋結果
final placeImageUrlProvider =
    FutureProvider.family<String?, String>((ref, placeName) async {
  final service = ref.read(wikimediaImageServiceProvider);
  return service.searchImage(placeName);
});

/// 地點圖片元件
///
/// 優先顯示從 Wikimedia Commons 取得的免費圖片，
/// 找不到圖片時顯示類別圖示作為備援
class PlaceImageWidget extends ConsumerWidget {
  final Place place;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const PlaceImageWidget({
    super.key,
    required this.place,
    this.width = 64,
    this.height = 64,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrlAsync = ref.watch(placeImageUrlProvider(place.name));

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrlAsync.when(
          data: (imageUrl) {
            if (imageUrl == null) {
              return _buildCategoryFallback();
            }
            return _buildNetworkImage(imageUrl);
          },
          loading: () => _buildLoadingPlaceholder(),
          error: (_, __) => _buildCategoryFallback(),
        ),
      ),
    );
  }

  /// 建立網路圖片元件
  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) => _buildCategoryFallback(),
    );
  }

  /// 建立載入中的佔位元件
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: place.category.color.withValues(alpha: 0.2),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: place.category.color,
          ),
        ),
      ),
    );
  }

  /// 建立類別圖示備援元件
  Widget _buildCategoryFallback() {
    return Image.asset(
      place.category.imageAssetPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}
