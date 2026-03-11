import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// 路線進度指示器
///
/// 顯示路線中所有停靠站的進度，以編號圓圈和連線呈現。
/// 當前站以主色標示，已完成站以綠色標示，未到達站以灰色標示。
class RouteProgressIndicator extends StatelessWidget {
  final int totalStops;
  final int currentIndex;

  const RouteProgressIndicator({
    super.key,
    required this.totalStops,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalStops * 2 - 1, (i) {
          if (i.isOdd) {
            return _buildConnector(i ~/ 2);
          }
          return _buildCircle(i ~/ 2);
        }),
      ),
    );
  }

  Widget _buildCircle(int index) {
    final isCompleted = index < currentIndex;
    final isCurrent = index == currentIndex;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isCurrent) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isCompleted) {
      bgColor = AppColors.success;
      borderColor = AppColors.success;
      textColor = Colors.white;
    } else {
      bgColor = Colors.transparent;
      borderColor = AppColors.textSecondaryDark;
      textColor = AppColors.textSecondaryDark;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildConnector(int index) {
    final isCompleted = index < currentIndex;
    return Container(
      width: 24,
      height: 2,
      color: isCompleted
          ? AppColors.success
          : AppColors.textSecondaryDark.withValues(alpha: 0.4),
    );
  }
}
