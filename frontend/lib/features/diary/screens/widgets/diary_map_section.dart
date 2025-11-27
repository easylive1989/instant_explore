import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_diary/core/utils/ui_utils.dart';

class DiaryMapSection extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryMapSection({super.key, required this.entry});

  /// 開啟 Google 地圖
  Future<void> _openGoogleMaps(BuildContext context) async {
    if (entry.latitude == null || entry.longitude == null) {
      return;
    }

    final lat = entry.latitude!;
    final lng = entry.longitude!;
    final label = entry.placeName ?? '地點';

    // Google Maps URL
    // 格式：https://www.google.com/maps/search/?api=1&query=lat,lng&query_place_id=place_id
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query=$label',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // 使用外部 App 開啟
        );
      } else {
        if (context.mounted) {
          UiUtils.showErrorSnackBar(context, '無法開啟 Google 地圖');
        }
      }
    } catch (e) {
      if (context.mounted) {
        UiUtils.showErrorSnackBar(context, '開啟地圖失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果沒有地點資訊，不顯示整個區塊
    if (entry.placeName == null &&
        (entry.latitude == null || entry.longitude == null)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 地點資訊
        if (entry.placeName != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.placeName!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ThemeConfig.neutralText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.placeAddress != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.placeAddress!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ThemeConfig.neutralText.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 地圖
        if (entry.latitude != null && entry.longitude != null) ...[
          GestureDetector(
            onTap: () => _openGoogleMaps(context),
            child: Stack(
              children: [
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
                        target: LatLng(entry.latitude!, entry.longitude!),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(entry.id),
                          position: LatLng(entry.latitude!, entry.longitude!),
                          infoWindow: InfoWindow(title: entry.placeName),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      // 禁用地圖互動，讓點擊事件可以被 GestureDetector 捕獲
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                  ),
                ),
                // 提示開啟外部地圖的浮動按鈕
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '在 Google 地圖中開啟',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
