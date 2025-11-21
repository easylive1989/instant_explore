import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';
import '../../images/services/image_upload_service.dart';
import 'diary_create_screen.dart';
import '../../../core/constants/spacing_constants.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/utils/image_brightness_helper.dart';

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
  Color _iconColor = Colors.white; // 預設白色

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _analyzeImageBrightness();
  }

  /// 分析圖片亮度並設定 icon 顏色
  Future<void> _analyzeImageBrightness() async {
    if (_currentEntry.imagePaths.isEmpty) {
      // 沒有圖片時使用黑色 icon（配合淺色背景）
      if (mounted) {
        setState(() {
          _iconColor = Colors.black;
        });
      }
      return;
    }

    try {
      final imageUrl = _imageUploadService.getImageUrl(
        _currentEntry.imagePaths.first,
      );
      final imageProvider = CachedNetworkImageProvider(imageUrl);

      final foregroundColor = await ImageBrightnessHelper.getForegroundColor(
        imageProvider,
        defaultColor: Colors.white,
      );

      if (mounted) {
        setState(() {
          _iconColor = foregroundColor;
        });
      }
    } catch (e) {
      debugPrint('分析圖片亮度失敗: $e');
      // 保持預設白色
    }
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
          // 重新分析圖片亮度
          _analyzeImageBrightness();
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
            expandedHeight: 150,
            pinned: true,
            iconTheme: IconThemeData(color: _iconColor),
            actions: [
              if (_isDeleting)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _iconColor),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editDiary();
                    } else if (value == 'delete') {
                      _deleteDiary();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 12),
                          Text('編輯'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 12),
                          Text('刪除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
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
            child: Container(
              margin: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeConfig.neutralBorder, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期與評分
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: ThemeConfig.accentColor,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          dateFormat.format(_currentEntry.visitDate),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: ThemeConfig.neutralText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // 地點資訊
                    if (_currentEntry.placeName != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: ThemeConfig.accentColor,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentEntry.placeName!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: ThemeConfig.neutralText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_currentEntry.placeAddress != null) ...[
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    _currentEntry.placeAddress!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: ThemeConfig.neutralText.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],

                    // 內容（Quill 富文本）
                    if (_currentEntry.content != null &&
                        _currentEntry.content!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: ThemeConfig.neutralLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildQuillContent(_currentEntry.content!),
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],

                    // 標籤
                    if (_currentEntry.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _currentEntry.tags.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ThemeConfig.neutralBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ThemeConfig.neutralText,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],

                    // 圖片集
                    if (_currentEntry.imagePaths.length > 1) ...[
                      Text(
                        '照片 (${_currentEntry.imagePaths.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ThemeConfig.neutralText.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                        ),
                        itemCount: _currentEntry.imagePaths.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ThemeConfig.neutralBorder,
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CachedNetworkImage(
                                imageUrl: _imageUploadService.getImageUrl(
                                  _currentEntry.imagePaths[index],
                                ),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: ThemeConfig.neutralLight,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: ThemeConfig.neutralLight,
                                  child: Icon(
                                    Icons.error_outline,
                                    color: ThemeConfig.neutralBorder,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],

                    // 地圖
                    if (_currentEntry.latitude != null &&
                        _currentEntry.longitude != null) ...[
                      Text(
                        '位置',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ThemeConfig.neutralText.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ThemeConfig.neutralBorder,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
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
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立 Quill 內容顯示
  Widget _buildQuillContent(String content) {
    try {
      final deltaJson = jsonDecode(content);
      final document = Document.fromJson(deltaJson);
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return QuillEditor.basic(
        controller: controller,
        config: const QuillEditorConfig(padding: EdgeInsets.zero),
      );
    } catch (e) {
      // 如果無法解析，顯示為純文字（向後相容）
      return Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.8,
          color: ThemeConfig.neutralText,
        ),
      );
    }
  }
}
