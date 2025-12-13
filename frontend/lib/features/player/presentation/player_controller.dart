import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/application/narration_generation_exception.dart';
import 'package:context_app/features/player/models/narration_error_type.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/player/application/start_narration_use_case.dart';
import 'package:context_app/features/player/presentation/player_state.dart';

/// 播放器控制器
///
/// 使用 StateNotifier 管理播放器狀態
/// 負責協調 Use Cases 和 TTS Service
class PlayerController extends StateNotifier<PlayerState> {
  final _log = Logger('PlayerController');
  final StartNarrationUseCase _startNarrationUseCase;
  final TtsService _ttsService;

  StreamSubscription<void>? _ttsCompleteSubscription;
  StreamSubscription<void>? _ttsStartSubscription;
  StreamSubscription<String>? _ttsErrorSubscription;
  StreamSubscription<TtsProgress>? _ttsProgressSubscription;

  Timer? _progressTimer;

  PlayerController(this._startNarrationUseCase, this._ttsService)
    : super(PlayerState.initial()) {
    _setupTtsListeners();
  }

  /// 初始化並開始生成導覽
  ///
  /// [place] 地點資訊
  /// [style] 導覽風格
  /// [language] 語言代碼（預設為 'zh-TW'）
  Future<void> initialize(
    Place place,
    NarrationStyle style, {
    String language = 'zh-TW',
  }) async {
    _log.info('Initializing player for place: ${place.name}');

    // 設定為載入中狀態
    state = state.loading();

    try {
      // 使用 StartNarrationUseCase 生成導覽
      final narration = await _startNarrationUseCase.execute(
        place: place,
        style: style,
        language: language,
      );

      // 更新狀態為就緒
      state = state.ready(narration);
      _log.info('Player initialized and ready');
    } on NarrationGenerationException catch (e) {
      _log.severe('Failed to initialize: ${e.type}, raw: ${e.rawMessage}');
      state = state.error(e.type, message: e.rawMessage);

      if (e.context != null && e.context!.isNotEmpty) {
        _log.info('Error context: ${e.context}');
      }
    } catch (e, stackTrace) {
      _log.severe('Unexpected error during initialization', e, stackTrace);
      state = state.error(NarrationErrorType.unknown, message: e.toString());
    }
  }

  /// 設定 TTS 事件監聽器
  void _setupTtsListeners() {
    // 監聽播放完成事件
    _ttsCompleteSubscription = _ttsService.onComplete.listen((_) {
      _log.info('TTS playback completed');
      _stopProgressTimer();
      if (state.narration != null) {
        final updatedNarration = state.narration!.updateProgress(
          state.narration!.duration,
        );
        state = state.updateNarration(updatedNarration);
      }
    });

    // 監聽播放開始事件
    _ttsStartSubscription = _ttsService.onStart.listen((_) {
      _log.info('TTS playback started');
      _startProgressTimer();
    });

    // 監聽錯誤事件
    _ttsErrorSubscription = _ttsService.onError.listen((error) {
      _log.severe('TTS error: $error');
      state = state.error(NarrationErrorType.ttsPlaybackError, message: error);
    });

    // 監聽進度事件（可選，用於更精確的進度追蹤）
    _ttsProgressSubscription = _ttsService.onProgress.listen((progress) {
      // TTS 進度更新（字符級別）
      // 我們使用定時器追蹤時間進度，這裡可以用於段落高亮
      _log.fine('TTS progress: ${progress.progress * 100}%');
    });
  }

  /// 播放/暫停切換
  void playPause() {
    if (state.narration == null) {
      _log.warning('Cannot play/pause: narration not initialized');
      return;
    }

    if (state.isPlaying) {
      pause();
    } else if (state.isPaused || state.isReady || state.isCompleted) {
      play();
    }
  }

  /// 開始播放
  Future<void> play() async {
    if (state.narration == null) {
      _log.warning('Cannot play: narration not initialized');
      return;
    }

    _log.info('Starting playback');

    try {
      // 更新 Narration 聚合狀態
      final updatedNarration = state.narration!.play();

      // 如果是從完成狀態重新播放，需要從頭開始
      if (state.isCompleted) {
        await _ttsService.stop();
      }

      // 播放 TTS
      final success = await _ttsService.speak(
        state.narration!.content?.text ?? '',
      );

      if (success) {
        state = state.updateNarration(updatedNarration);
      } else {
        state = state.error(
          NarrationErrorType.ttsPlaybackError,
          message: '播放失敗',
        );
      }
    } catch (e) {
      _log.severe('Failed to play: $e');
      state = state.error(
        NarrationErrorType.ttsPlaybackError,
        message: '播放失敗：$e',
      );
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    if (state.narration == null) {
      _log.warning('Cannot pause: narration not initialized');
      return;
    }

    _log.info('Pausing playback');

    try {
      // 暫停 TTS
      await _ttsService.pause();

      // 更新 Narration 聚合狀態
      final updatedNarration = state.narration!.pause();
      state = state.updateNarration(updatedNarration);

      // 停止進度定時器
      _stopProgressTimer();
    } catch (e) {
      _log.severe('Failed to pause: $e');
      state = state.error(
        NarrationErrorType.ttsPlaybackError,
        message: '暫停失敗：$e',
      );
    }
  }

  /// 快進 10 秒
  void seekForward() {
    _seekBy(10);
  }

  /// 快退 10 秒
  void seekBackward() {
    _seekBy(-10);
  }

  /// 快進/快退指定秒數
  void _seekBy(int seconds) {
    if (state.narration == null) {
      _log.warning('Cannot seek: narration not initialized');
      return;
    }

    _log.info('Seeking by $seconds seconds');

    try {
      // 更新 Narration 聚合
      final updatedNarration = seconds > 0
          ? state.narration!.seekForward(seconds)
          : state.narration!.seekBackward(seconds.abs());

      state = state.updateNarration(updatedNarration);

      // 注意：flutter_tts 不支援精確的 seek 操作
      // 需要重新開始播放並跳到指定位置
      // 這是一個簡化實現，實際可能需要更複雜的邏輯
      _log.warning(
        'TTS seek not fully implemented - position updated but playback not adjusted',
      );
    } catch (e) {
      _log.severe('Failed to seek: $e');
    }
  }

  /// 開始進度定時器
  void _startProgressTimer() {
    _stopProgressTimer();

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.narration != null && state.isPlaying) {
        final newPosition = state.currentPosition + 1;

        // 更新 Narration 進度
        final updatedNarration = state.narration!.updateProgress(newPosition);
        state = state.updateNarration(updatedNarration);
      }
    });
  }

  /// 停止進度定時器
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void dispose() {
    _log.info('Disposing player controller');

    // 停止播放
    _ttsService.stop();

    // 取消訂閱
    _ttsCompleteSubscription?.cancel();
    _ttsStartSubscription?.cancel();
    _ttsErrorSubscription?.cancel();
    _ttsProgressSubscription?.cancel();

    // 停止定時器
    _stopProgressTimer();

    super.dispose();
  }
}
