import 'dart:math' as math;

import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/shared/widgets/journal/journal_category.dart';
import 'package:flutter/material.dart';

/// 地圖上的地點標記，對應設計稿的 `.map-pin`：水滴造型、紙色描邊與內點。
///
/// 造型做法與設計稿一致——圓角 `50% 50% 50% 0` 的方塊旋轉 -45°，讓左下角
/// 成為朝下的尖端；內點再轉回 +45° 保持正圓的視覺位置。
class PlaceMapPin extends StatelessWidget {
  const PlaceMapPin({super.key, required this.category, this.onTap});

  final JournalCategory category;
  final VoidCallback? onTap;

  /// 設計稿的 30×30；[markerSize] 供 `Marker` 設定尺寸時共用。
  static const double markerSize = 30;

  static const Color _stroke = Color(0xFFFBF1E9);
  static const Color _urban = Color(0xFF6A4A2F);

  /// 設計稿只替 urban 與 heritage 指定了顏色，其餘沿用 clay。
  Color _fill(LorescapeTokens tokens) {
    return switch (category) {
      JournalCategory.urban => _urban,
      JournalCategory.heritage => tokens.clayDeep,
      _ => tokens.clay,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.rotate(
        angle: -math.pi / 4,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: _fill(tokens),
            border: Border.all(color: _stroke, width: 2.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(markerSize),
              topRight: Radius.circular(markerSize),
              bottomRight: Radius.circular(markerSize),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x661C140A),
                offset: Offset(0, 4),
                blurRadius: 9,
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: _stroke,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
