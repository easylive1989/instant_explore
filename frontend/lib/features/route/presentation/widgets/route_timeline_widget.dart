import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 路線時間軸視圖
///
/// 以時間軸方式呈現所有停靠站，
/// 站與站之間顯示步行距離、時間及導航按鈕。
class RouteTimelineWidget extends StatelessWidget {
  final List<RouteStop> stops;

  const RouteTimelineWidget({super.key, required this.stops});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: stops.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isEven) {
          final stopIndex = index ~/ 2;
          return _TimelineStopItem(
            stop: stops[stopIndex],
            index: stopIndex,
            isFirst: stopIndex == 0,
            isLast: stopIndex == stops.length - 1,
          );
        }
        final fromIndex = index ~/ 2;
        return _TimelineConnector(stop: stops[fromIndex]);
      },
    );
  }
}

class _TimelineStopItem extends StatelessWidget {
  final RouteStop stop;
  final int index;
  final bool isFirst;
  final bool isLast;

  const _TimelineStopItem({
    required this.stop,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.primary : AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isFirst ? Colors.white : AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: RouteStopCard(stop: stop)),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final RouteStop stop;

  const _TimelineConnector({required this.stop});

  @override
  Widget build(BuildContext context) {
    final distance = stop.distanceToNext;
    final walkingTime = stop.walkingTimeToNext;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Center(
            child: CustomPaint(
              size: const Size(2, 60),
              painter: _DashedLinePainter(
                color: AppColors.textSecondaryDark.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: AppColors.textSecondaryDark,
                  size: 18,
                ),
                const SizedBox(width: 6),
                if (walkingTime != null)
                  Text(
                    'route.walking_time_value'.tr(
                      namedArgs: {'minutes': walkingTime.round().toString()},
                    ),
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                if (distance != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatDistance(distance),
                    style: const TextStyle(
                      color: AppColors.textTertiaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashGap = 4.0;
    var startY = 0.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
