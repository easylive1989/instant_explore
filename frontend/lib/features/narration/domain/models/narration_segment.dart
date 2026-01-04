import 'package:equatable/equatable.dart';

/// 導覽段落值對象
///
/// 包含段落文本及其在完整文本中的位置範圍
class NarrationSegment extends Equatable {
  /// 段落文本
  final String text;

  /// 在完整文本中的起始位置（含）
  final int startPosition;

  /// 在完整文本中的結束位置（不含）
  final int endPosition;

  const NarrationSegment({
    required this.text,
    required this.startPosition,
    required this.endPosition,
  });

  /// 檢查指定位置是否在此段落範圍內
  bool containsPosition(int position) {
    return position >= startPosition && position < endPosition;
  }

  @override
  List<Object?> get props => [text, startPosition, endPosition];
}
