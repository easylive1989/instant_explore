/// 導覽內容值對象
///
/// 包含AI生成的導覽文本及其相關屬性
class NarrationContent {
  /// 完整的導覽文本
  final String text;

  /// 文本段落列表（用於同步顯示和高亮）
  /// 每個段落約1-2句話
  final List<String> segments;

  /// 預估播放時長（秒）
  /// 根據文本長度和語速估算
  final int estimatedDuration;

  const NarrationContent({
    required this.text,
    required this.segments,
    required this.estimatedDuration,
  });

  /// 從完整文本創建 NarrationContent
  ///
  /// 自動將文本分段並估算播放時長
  /// [text] 完整的導覽文本
  /// [charsPerSecond] 每秒朗讀的字數，預設為5（適合中文）
  factory NarrationContent.fromText(String text, {int charsPerSecond = 5}) {
    // 按照句號、問號、驚嘆號分段
    final segments = _splitIntoSegments(text);

    // 估算播放時長：字數 / 每秒字數
    final estimatedDuration = (text.length / charsPerSecond).ceil();

    return NarrationContent(
      text: text,
      segments: segments,
      estimatedDuration: estimatedDuration,
    );
  }

  /// 將文本分段
  ///
  /// 按照標點符號（。！？）分段，保持每段1-2句話
  static List<String> _splitIntoSegments(String text) {
    // 移除首尾空白
    final cleanText = text.trim();
    if (cleanText.isEmpty) return [];

    // 按照句號、問號、驚嘆號分段
    final List<String> segments = [];
    final buffer = StringBuffer();

    for (int i = 0; i < cleanText.length; i++) {
      final char = cleanText[i];
      buffer.write(char);

      // 檢查是否為句子結束
      if (char == '。' ||
          char == '！' ||
          char == '？' ||
          char == '.' ||
          char == '!' ||
          char == '?') {
        // 檢查後面是否還有字符
        if (i + 1 < cleanText.length) {
          // 添加當前段落
          final segment = buffer.toString().trim();
          if (segment.isNotEmpty) {
            segments.add(segment);
          }
          buffer.clear();
        }
      }
    }

    // 添加最後一段（如果有）
    final lastSegment = buffer.toString().trim();
    if (lastSegment.isNotEmpty) {
      segments.add(lastSegment);
    }

    return segments;
  }

  /// 根據當前播放位置獲取當前段落索引
  ///
  /// [currentPosition] 當前播放位置（秒）
  /// 返回當前應該高亮的段落索引
  int getCurrentSegmentIndex(int currentPosition) {
    if (segments.isEmpty || estimatedDuration == 0) return 0;

    // 估算每個段落的時長
    final durationPerSegment = estimatedDuration / segments.length;

    // 計算當前段落索引
    final index = (currentPosition / durationPerSegment).floor();

    // 確保索引在有效範圍內
    return index.clamp(0, segments.length - 1);
  }

  @override
  String toString() {
    return 'NarrationContent(text: ${text.length} chars, '
        'segments: ${segments.length}, '
        'duration: ${estimatedDuration}s)';
  }
}
