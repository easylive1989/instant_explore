import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';
import '../../images/services/image_upload_service.dart';
import 'diary_create_screen.dart';

/// 日記詳情畫面
class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  final DiaryRepository _repository = DiaryRepositoryImpl();
  final ImageUploadService _imageUploadService = ImageUploadService();
  late DiaryEntry _currentEntry;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  Future<void> _deleteDiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除這篇日記嗎?此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // 刪除圖片
      if (_currentEntry.imagePaths.isNotEmpty) {
        await _imageUploadService.deleteMultipleImages(
          _currentEntry.imagePaths,
        );
      }

      // 刪除日記
      await _repository.deleteDiaryEntry(_currentEntry.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('日記已刪除')));
        Navigator.of(context).pop(true); // 返回 true 表示已刪除
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
      }
    }
  }

  Future<void> _editDiary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryCreateScreen(existingEntry: _currentEntry),
      ),
    );

    if (result == true && mounted) {
      // 重新載入日記資料
      try {
        final updatedEntry = await _repository.getDiaryEntryById(
          _currentEntry.id,
        );
        if (updatedEntry != null) {
          setState(() {
            _currentEntry = updatedEntry;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('重新載入失敗: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _currentEntry.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: _currentEntry.imagePaths.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _imageUploadService.getImageUrl(
                            _currentEntry.imagePaths.first,
                          ),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 64,
                            ),
                          ),
                        ),
                        // 漸層遮罩
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black38],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期與評分
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(_currentEntry.visitDate),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (_currentEntry.rating != null) ...[
                        const Spacer(),
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < _currentEntry.rating!
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 地點資訊
                  if (_currentEntry.placeName != null) ...[
                    _buildInfoRow(
                      icon: Icons.location_on,
                      title: '地點',
                      content: _currentEntry.placeName!,
                      theme: theme,
                    ),
                    if (_currentEntry.placeAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          _currentEntry.placeAddress!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // 內容
                  if (_currentEntry.content != null &&
                      _currentEntry.content!.isNotEmpty) ...[
                    Text(
                      '心得',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentEntry.content!,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 標籤
                  if (_currentEntry.tags.isNotEmpty) ...[
                    Text(
                      '標籤',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentEntry.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 圖片集
                  if (_currentEntry.imagePaths.length > 1) ...[
                    Text(
                      '照片 (${_currentEntry.imagePaths.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _currentEntry.imagePaths.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _imageUploadService.getImageUrl(
                              _currentEntry.imagePaths[index],
                            ),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 地圖
                  if (_currentEntry.latitude != null &&
                      _currentEntry.longitude != null) ...[
                    Text(
                      '位置',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentEntry.latitude!,
                              _currentEntry.longitude!,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(_currentEntry.id),
                              position: LatLng(
                                _currentEntry.latitude!,
                                _currentEntry.longitude!,
                              ),
                              infoWindow: InfoWindow(
                                title: _currentEntry.placeName,
                              ),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isDeleting
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'delete',
                  onPressed: _deleteDiary,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: 'edit',
                  onPressed: _editDiary,
                  icon: const Icon(Icons.edit),
                  label: const Text('編輯'),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(content, style: theme.textTheme.bodyLarge)],
          ),
        ),
      ],
    );
  }
}
