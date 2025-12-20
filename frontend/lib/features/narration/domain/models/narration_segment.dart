/// 導覽段落值對象
///
/// 包含段落文本及其在完整文本中的位置範圍
class NarrationSegment {
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

  /// 段落長度
  int get length => text.length;

  @override
  String toString() {
    return 'NarrationSegment(text: "${text.substring(0, text.length > 20 ? 20 : text.length)}...", '
        'range: $startPosition-$endPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NarrationSegment &&
        other.text == text &&
        other.startPosition == startPosition &&
        other.endPosition == endPosition;
  }

  @override
  int get hashCode => Object.hash(text, startPosition, endPosition);
}
