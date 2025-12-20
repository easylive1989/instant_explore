import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// TTS 語音合成服務
///
/// 封裝 flutter_tts 套件，提供統一的文字轉語音介面
class TtsService {
  final FlutterTts _tts = FlutterTts();

  /// 播放進度回調（當前播放到的字符位置和文本長度）
  final StreamController<TtsProgress> _progressController =
      StreamController<TtsProgress>.broadcast();

  /// 播放完成回調
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();

  /// 播放開始回調
  final StreamController<void> _startController =
      StreamController<void>.broadcast();

  /// 播放暫停回調
  final StreamController<void> _pauseController =
      StreamController<void>.broadcast();

  /// 播放錯誤回調
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  bool _isInitialized = false;
  String _currentText = '';

  /// 播放進度事件流
  Stream<TtsProgress> get onProgress => _progressController.stream;

  /// 播放完成事件流
  Stream<void> get onComplete => _completeController.stream;

  /// 播放開始事件流
  Stream<void> get onStart => _startController.stream;

  /// 播放暫停事件流
  Stream<void> get onPause => _pauseController.stream;

  /// 播放錯誤事件流
  Stream<String> get onError => _errorController.stream;

  /// 初始化 TTS 服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 設定預設值
      await _tts.setLanguage('zh-TW'); // 預設繁體中文
      await _tts.setSpeechRate(0.5); // 語速：0.5 (較慢，適合導覽)
      await _tts.setVolume(1.0); // 音量：最大
      await _tts.setPitch(1.0); // 音調：正常

      // iOS 特定設定
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      // 設定事件處理器
      _tts.setStartHandler(() {
        _startController.add(null);
      });

      _tts.setCompletionHandler(() {
        _completeController.add(null);
      });

      _tts.setPauseHandler(() {
        _pauseController.add(null);
      });

      _tts.setErrorHandler((message) {
        _errorController.add(message);
      });

      // 設定進度處理器
      _tts.setProgressHandler((text, start, end, word) {
        // start: 當前播放到的字符位置
        // end: 當前詞組的結束位置
        // word: 當前播放的詞組
        if (_currentText.isNotEmpty) {
          final progress = TtsProgress(
            text: _currentText,
            currentPosition: start,
            totalLength: _currentText.length,
            currentWord: word,
          );
          _progressController.add(progress);
        }
      });

      _isInitialized = true;
    } catch (e) {
      _errorController.add('初始化 TTS 失敗: $e');
      rethrow;
    }
  }

  /// 播放文本
  ///
  /// [text] 要播放的文本
  /// 返回播放是否成功開始
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      return false;
    }

    try {
      _currentText = text;
      final result = await _tts.speak(text);
      return result == 1; // 1 表示成功
    } catch (e) {
      _errorController.add('播放失敗: $e');
      return false;
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      _errorController.add('暫停失敗: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _tts.stop();
      _currentText = '';
    } catch (e) {
      _errorController.add('停止失敗: $e');
    }
  }

  /// 設定語言
  ///
  /// [language] 語言
  Future<void> setLanguage(Language language) async {
    try {
      await _tts.setLanguage(language.code);
    } catch (e) {
      _errorController.add('設定語言失敗: $e');
    }
  }

  /// 設定語速
  ///
  /// [rate] 語速 (0.0 - 1.0)
  /// 推薦值：0.5 (適合導覽)
  Future<void> setRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.0, 1.0);
      await _tts.setSpeechRate(clampedRate);
    } catch (e) {
      _errorController.add('設定語速失敗: $e');
    }
  }

  /// 設定音量
  ///
  /// [volume] 音量 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _tts.setVolume(clampedVolume);
    } catch (e) {
      _errorController.add('設定音量失敗: $e');
    }
  }

  /// 設定音調
  ///
  /// [pitch] 音調 (0.5 - 2.0)
  /// 1.0 為正常音調
  Future<void> setPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      await _tts.setPitch(clampedPitch);
    } catch (e) {
      _errorController.add('設定音調失敗: $e');
    }
  }

  /// 取得可用的語言列表
  Future<List<dynamic>> getLanguages() async {
    try {
      return await _tts.getLanguages;
    } catch (e) {
      return [];
    }
  }

  /// 取得可用的語音列表
  Future<List<dynamic>> getVoices() async {
    try {
      return await _tts.getVoices;
    } catch (e) {
      return [];
    }
  }

  /// 檢查是否正在播放
  Future<bool> isPlaying() async {
    try {
      // flutter_tts 沒有直接的 isPlaying 方法
      // 我們需要自己追蹤狀態
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    try {
      await stop();
      await _progressController.close();
      await _completeController.close();
      await _startController.close();
      await _pauseController.close();
      await _errorController.close();
      _isInitialized = false;
    } catch (e) {
      // Ignore errors during disposal
    }
  }
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
