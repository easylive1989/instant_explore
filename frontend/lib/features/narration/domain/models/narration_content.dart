/// 段落字符位置範圍
class _SegmentCharRange {
  /// 段落起始字符位置
  final int start;

  /// 段落結束字符位置
  final int end;

  const _SegmentCharRange(this.start, this.end);
}

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

  /// 段落字符位置範圍映射
  /// 每個元素是一個 (startIndex, endIndex) 對，表示該段落在完整文本中的字符範圍
  final List<_SegmentCharRange> _segmentCharRanges;

  /// 私有建構子，確保只能通過 factory 方法創建實例
  const NarrationContent._({
    required this.text,
    required this.segments,
    required this.estimatedDuration,
    required List<_SegmentCharRange> segmentCharRanges,
  }) : _segmentCharRanges = segmentCharRanges;

  /// 從完整文本創建 NarrationContent
  ///
  /// 自動將文本分段並估算播放時長
  /// [text] 完整的導覽文本
  /// [language] 語言代碼 (例如: 'zh-TW', 'en-US')，用於決定語速
  factory NarrationContent.fromText(String text, {String language = 'zh-TW'}) {
    // 按照句號、問號、驚嘆號分段
    final segments = _splitIntoSegments(text);

    // 建立段落字符位置映射表
    final segmentCharRanges = _buildSegmentCharRanges(text, segments);

    // 根據語言決定每秒字數
    // 中文：約 4 字/秒 (TTS rate 0.5)
    // 英文/其他：約 18 字/秒
    final int charsPerSecond = language.toLowerCase().startsWith('zh') ? 4 : 18;

    // 估算播放時長：字數 / 每秒字數
    final estimatedDuration = (text.length / charsPerSecond).ceil();

    return NarrationContent._(
      text: text,
      segments: segments,
      estimatedDuration: estimatedDuration,
      segmentCharRanges: segmentCharRanges,
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

  /// 建立段落字符位置映射表
  ///
  /// [fullText] 完整的導覽文本
  /// [segments] 分段後的段落列表
  /// 返回每個段落在完整文本中的字符位置範圍
  static List<_SegmentCharRange> _buildSegmentCharRanges(
    String fullText,
    List<String> segments,
  ) {
    final ranges = <_SegmentCharRange>[];
    int currentPos = 0;

    for (final segment in segments) {
      // 在完整文本中搜尋段落的位置
      final startPos = fullText.indexOf(segment, currentPos);

      if (startPos != -1) {
        // 找到段落，記錄起始和結束位置
        final endPos = startPos + segment.length;
        ranges.add(_SegmentCharRange(startPos, endPos));
        // 更新搜尋起點，避免找到重複的段落
        currentPos = endPos;
      } else {
        // 找不到段落（理論上不應發生），使用預估位置
        // 這是一個安全後備方案
        final estimatedStart = currentPos;
        final estimatedEnd = estimatedStart + segment.length;
        ranges.add(_SegmentCharRange(estimatedStart, estimatedEnd));
        currentPos = estimatedEnd;
      }
    }

    return ranges;
  }

  /// 根據字符位置獲取段落索引（精確方法）
  ///
  /// [charPosition] TTS 當前播放的字符位置
  /// 返回當前應該高亮的段落索引
  int getSegmentIndexByCharPosition(int charPosition) {
    if (_segmentCharRanges.isEmpty) return 0;

    // 找到包含當前字符位置的段落
    for (int i = 0; i < _segmentCharRanges.length; i++) {
      final range = _segmentCharRanges[i];
      if (charPosition >= range.start && charPosition < range.end) {
        return i;
      }
    }

    // 如果超出所有範圍，返回最後一個段落
    if (charPosition >= _segmentCharRanges.last.end) {
      return _segmentCharRanges.length - 1;
    }

    // 預設返回第一個段落
    return 0;
  }

  /// 根據當前播放位置獲取當前段落索引（基於時間估算）
  ///
  /// [currentPosition] 當前播放位置（秒）
  /// 返回當前應該高亮的段落索引
  ///
  /// @Deprecated('使用 getSegmentIndexByCharPosition 以獲得更精確的同步')
  @Deprecated('使用 getSegmentIndexByCharPosition 以獲得更精確的同步')
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
