import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:context_app/features/narration/domain/services/tts_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 基於 flutter_tts 的 TTS 語音合成服務實作
class FlutterTtsService implements TtsService {
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
  bool _isPaused = false;
  String _currentText = '';

  @override
  Stream<TtsProgress> get onProgress => _progressController.stream;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  Stream<void> get onStart => _startController.stream;

  @override
  Stream<void> get onPause => _pauseController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
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
        _isPaused = false;
        _startController.add(null);
      });

      _tts.setCompletionHandler(() {
        _isPaused = false;
        _completeController.add(null);
      });

      _tts.setPauseHandler(() {
        _isPaused = true;
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
    }
  }

  @override
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      return false;
    }

    try {
      // 如果處於暫停狀態，需要先停止 TTS 引擎
      // 這是因為在 iOS 上，暫停狀態下直接呼叫 speak() 可能會失敗
      if (_isPaused) {
        await _tts.stop();
        _isPaused = false;
      }

      _currentText = text;
      final result = await _tts.speak(text);
      return result == 1; // 1 表示成功
    } catch (e) {
      _errorController.add('播放失敗: $e');
      return false;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      _errorController.add('暫停失敗: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
      _currentText = '';
      _isPaused = false;
    } catch (e) {
      _errorController.add('停止失敗: $e');
    }
  }

  @override
  Future<void> setLanguage(Language language) async {
    try {
      await _tts.setLanguage(language.code);
    } catch (e) {
      _errorController.add('設定語言失敗: $e');
    }
  }

  @override
  Future<void> setRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.0, 1.0);
      await _tts.setSpeechRate(clampedRate);
    } catch (e) {
      _errorController.add('設定語速失敗: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _tts.setVolume(clampedVolume);
    } catch (e) {
      _errorController.add('設定音量失敗: $e');
    }
  }

  @override
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

  @override
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

