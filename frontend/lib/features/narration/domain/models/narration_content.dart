import 'package:context_app/features/narration/domain/models/narration_content_exception.dart';
import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 導覽內容值對象
///
/// 包含AI生成的導覽文本及其相關屬性
class NarrationContent {
  /// 完整的導覽文本
  final String text;

  /// 導覽段落列表（用於同步顯示和高亮）
  /// 每個段落包含文本及其在完整文本中的位置範圍
  final List<NarrationSegment> segments;

  /// 語言
  final Language language;

  /// 私有建構子，確保只能通過 factory 方法創建實例
  const NarrationContent._({
    required this.text,
    required this.segments,
    required this.language,
  });

  /// 從完整文本創建 NarrationContent
  ///
  /// 自動將文本分段
  /// [text] 完整的導覽文本
  /// [language] 語言
  ///
  /// 拋出 [NarrationContentException] 如果：
  /// - 文本為空或只有空白字符
  /// - 文本長度少於 10 個字符
  /// - 無法分段（segments 為空）
  factory NarrationContent.create(String text, {required Language language}) {
    // 驗證文本不為空
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw NarrationContentException.contentFailed(
        rawMessage: 'Narration text is empty',
      );
    }

    // 驗證文本長度（最少需要 10 個字符）
    if (trimmedText.length < 10) {
      throw NarrationContentException.contentFailed(
        rawMessage:
            'Narration is too short: ${trimmedText.length} chars (min: 10)',
      );
    }

    // 按照句號、問號、驚嘆號分段並建立 NarrationSegment
    final segments = _buildSegments(text);

    // 驗證分段結果
    if (segments.isEmpty) {
      throw NarrationContentException.contentFailed(
        rawMessage: 'Failed to segment narration',
      );
    }

    return NarrationContent._(
      text: text,
      segments: segments,
      language: language,
    );
  }

  factory NarrationContent.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String;
    final segmentTexts = (json['segments'] as List).cast<String>();
    final languageCode = json['language'] as String? ?? 'zh-TW';
    final language = Language.fromString(languageCode);

    // 從段落文本重建 NarrationSegment（包含位置資訊）
    final segments = _buildSegmentsFromTexts(text, segmentTexts);

    return NarrationContent._(
      text: text,
      segments: segments,
      language: language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'segments': segments.map((s) => s.text).toList(),
      'language': language.code,
    };
  }

  /// 建立段落列表（包含文本和位置資訊）
  ///
  /// [fullText] 完整的導覽文本
  /// 返回 NarrationSegment 列表
  static List<NarrationSegment> _buildSegments(String fullText) {
    // 移除首尾空白
    final cleanText = fullText.trim();
    if (cleanText.isEmpty) return [];

    // 按照句號、問號、驚嘆號分段
    final List<String> segmentTexts = [];
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
            segmentTexts.add(segment);
          }
          buffer.clear();
        }
      }
    }

    // 添加最後一段（如果有）
    final lastSegment = buffer.toString().trim();
    if (lastSegment.isNotEmpty) {
      segmentTexts.add(lastSegment);
    }

    // 從段落文本建立 NarrationSegment（包含位置資訊）
    return _buildSegmentsFromTexts(fullText, segmentTexts);
  }

  /// 從段落文本列表建立 NarrationSegment 列表
  ///
  /// [fullText] 完整的導覽文本
  /// [segmentTexts] 段落文本列表
  /// 返回 NarrationSegment 列表
  static List<NarrationSegment> _buildSegmentsFromTexts(
    String fullText,
    List<String> segmentTexts,
  ) {
    final segments = <NarrationSegment>[];
    int currentPos = 0;

    for (final segmentText in segmentTexts) {
      // 在完整文本中搜尋段落的位置
      final startPos = fullText.indexOf(segmentText, currentPos);

      if (startPos != -1) {
        // 找到段落，記錄起始和結束位置
        final endPos = startPos + segmentText.length;
        segments.add(
          NarrationSegment(
            text: segmentText,
            startPosition: startPos,
            endPosition: endPos,
          ),
        );
        // 更新搜尋起點，避免找到重複的段落
        currentPos = endPos;
      } else {
        // 找不到段落（理論上不應發生），使用預估位置
        // 這是一個安全後備方案
        final estimatedStart = currentPos;
        final estimatedEnd = estimatedStart + segmentText.length;
        segments.add(
          NarrationSegment(
            text: segmentText,
            startPosition: estimatedStart,
            endPosition: estimatedEnd,
          ),
        );
        currentPos = estimatedEnd;
      }
    }

    return segments;
  }

  /// 根據字符位置獲取段落索引
  ///
  /// [charPosition] TTS 當前播放的字符位置
  /// 返回當前應該高亮的段落索引
  int getSegmentIndexByCharPosition(int charPosition) {
    if (segments.isEmpty) return 0;

    // 找到包含當前字符位置的段落
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].containsPosition(charPosition)) {
        return i;
      }
    }

    // 如果超出所有範圍，返回最後一個段落
    if (charPosition >= segments.last.endPosition) {
      return segments.length - 1;
    }

    // 預設返回第一個段落
    return 0;
  }

  @override
  String toString() {
    return 'NarrationContent(text: ${text.length} chars, '
        'segments: ${segments.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NarrationContent &&
        other.text == text &&
        other.segments.length == segments.length;
  }

  @override
  int get hashCode {
    return Object.hash(text, segments.length);
  }
}
