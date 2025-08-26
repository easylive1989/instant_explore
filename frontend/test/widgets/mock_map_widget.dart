import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mock Map Widget for Testing
///
/// 模擬地圖 Widget，用於測試環境
/// 顯示模擬地圖介面，避免在測試中使用真實的 Google Maps
class MockMapWidget extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(CameraPosition)? onCameraMove;
  final void Function()? onCameraIdle;
  final void Function(LatLng)? onTap;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;

  const MockMapWidget({
    super.key,
    required this.initialCameraPosition,
    this.markers = const <Marker>{},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.mapType = MapType.normal,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Stack(
        children: [
          // 地圖背景
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.green[50],
            child: CustomPaint(painter: _MockMapPainter()),
          ),

          // 模擬標記點
          ...markers.map((marker) => _buildMockMarker(marker)),

          // 測試模式指示器
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'E2E 測試模式',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 模擬位置按鈕 (如果啟用)
          if (myLocationButtonEnabled)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  // 模擬按鈕點擊，觸發回調
                  if (onMapCreated != null) {
                    // 由於無法創建真實的 GoogleMapController，這裡簡化處理
                    debugPrint('🧪 MockMapWidget: 模擬我的位置按鈕點擊');
                  }
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  /// 建立模擬標記
  Widget _buildMockMarker(Marker marker) {
    // 簡化標記位置計算，固定在某些位置顯示
    final markerIndex = markers.toList().indexOf(marker);
    final leftOffset = 100.0 + (markerIndex * 80.0);
    final topOffset = 200.0 + (markerIndex * 50.0);

    return Positioned(
      left: leftOffset,
      top: topOffset,
      child: GestureDetector(
        onTap: () {
          if (marker.onTap != null) {
            marker.onTap!();
          }
          if (onTap != null) {
            onTap!(
              LatLng(
                initialCameraPosition.target.latitude,
                initialCameraPosition.target.longitude,
              ),
            );
          }
        },
        child: Column(
          children: [
            // 標記圖標
            Container(
              width: 30,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
            ),

            // 標記資訊 (如果有)
            if (marker.infoWindow.title?.isNotEmpty == true)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  marker.infoWindow.title!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 模擬地圖背景繪製器
class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 繪製網格線模擬地圖
    const gridSize = 50.0;

    // 垂直線
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 水平線
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 繪製一些模擬道路
    final roadPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 主要道路
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      roadPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
