import 'dart:async';

import 'package:context_app/features/settings/domain/models/language.dart';

/// TTS 語音合成服務介面
///
/// 定義文字轉語音的抽象契約，具體實作由 data 層提供。
abstract class TtsService {
  /// 播放進度事件流
  Stream<TtsProgress> get onProgress;

  /// 播放完成事件流
  Stream<void> get onComplete;

  /// 播放開始事件流
  Stream<void> get onStart;

  /// 播放暫停事件流
  Stream<void> get onPause;

  /// 播放錯誤事件流
  Stream<String> get onError;

  /// 初始化 TTS 服務
  Future<void> initialize();

  /// 播放文本，回傳是否成功開始
  Future<bool> speak(String text);

  /// 暫停播放
  Future<void> pause();

  /// 停止播放
  Future<void> stop();

  /// 設定語言
  Future<void> setLanguage(Language language);

  /// 設定語速（0.0 - 1.0）
  Future<void> setRate(double rate);

  /// 設定音量（0.0 - 1.0）
  Future<void> setVolume(double volume);

  /// 設定音調（0.5 - 2.0）
  Future<void> setPitch(double pitch);

  /// 釋放資源
  Future<void> dispose();
}

/// TTS 播放進度資訊
class TtsProgress {
  /// 完整文本
  final String text;

  /// 當前播放到的字符位置
  final int currentPosition;

  /// 文本總長度
  final int totalLength;

  /// 當前播放的詞組
  final String currentWord;

  const TtsProgress({
    required this.text,
    required this.currentPosition,
    required this.totalLength,
    required this.currentWord,
  });

  /// 播放進度百分比 (0.0 - 1.0)
  double get progress {
    if (totalLength == 0) return 0.0;
    return currentPosition / totalLength;
  }

  @override
  String toString() {
    return 'TtsProgress(position: $currentPosition/$totalLength, '
        'progress: ${(progress * 100).toStringAsFixed(1)}%, '
        'word: $currentWord)';
  }
}
