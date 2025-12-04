import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:travel_diary/core/utils/ui_utils.dart';

/// 圖片查看器類型
enum ImageSourceType {
  network, // 網路圖片 (URL)
  file, // 本地文件
}

/// 圖片資訊
class ImageInfo {
  final String path; // 圖片路徑或 URL
  final ImageSourceType type;

  const ImageInfo({required this.path, required this.type});
}

/// 完整圖片查看器
///
/// 支援功能：
/// - 單張/多張圖片查看
/// - 雙指縮放、單指平移
/// - 左右滑動切換圖片
/// - 顯示當前頁碼
/// - 下載圖片
class FullImageViewer extends StatefulWidget {
  final List<ImageInfo> images;
  final int initialIndex;
  final String? heroTag;

  const FullImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
  });

  /// 便捷建構函式：網路圖片
  factory FullImageViewer.network({
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTag,
  }) {
    return FullImageViewer(
      images: imageUrls
          .map((url) => ImageInfo(path: url, type: ImageSourceType.network))
          .toList(),
      initialIndex: initialIndex,
      heroTag: heroTag,
    );
  }

  /// 便捷建構函式：本地文件
  factory FullImageViewer.files({
    required List<String> filePaths,
    int initialIndex = 0,
    String? heroTag,
  }) {
    return FullImageViewer(
      images: filePaths
          .map((path) => ImageInfo(path: path, type: ImageSourceType.file))
          .toList(),
      initialIndex: initialIndex,
      heroTag: heroTag,
    );
  }

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 下載圖片到本地
  Future<void> _downloadImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentImage = widget.images[_currentIndex];

      if (currentImage.type == ImageSourceType.network) {
        // 下載網路圖片
        final response = await http.get(Uri.parse(currentImage.path));

        if (response.statusCode == 200) {
          // 獲取臨時目錄
          final directory = await getTemporaryDirectory();
          final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = '${directory.path}/$fileName';

          // 儲存文件
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            UiUtils.showSuccessSnackBar(context, '圖片已儲存到: $filePath');
          }
        } else {
          throw Exception('下載失敗: ${response.statusCode}');
        }
      } else {
        // 本地文件已經存在
        if (mounted) {
          UiUtils.showInfoSnackBar(context, '圖片路徑: ${currentImage.path}');
        }
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '下載失敗: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 建立圖片提供者
  ImageProvider _buildImageProvider(ImageInfo imageInfo) {
    if (imageInfo.type == ImageSourceType.network) {
      return CachedNetworkImageProvider(imageInfo.path);
    } else {
      return FileImage(File(imageInfo.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 圖片畫廊
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (context, index) {
              final imageInfo = widget.images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: _buildImageProvider(imageInfo),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                heroAttributes: widget.heroTag != null
                    ? PhotoViewHeroAttributes(tag: '${widget.heroTag}_$index')
                    : null,
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                color: Colors.white,
              ),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),

          // 頂部工具列
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 返回按鈕
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // 下載按鈕
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, color: Colors.white),
                      onPressed: _isLoading ? null : _downloadImage,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部頁碼指示器
          if (widget.images.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
