import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/core/services/tts_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/use_cases/narration_generation_exception.dart';
import 'package:context_app/features/narration/domain/models/narration.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/use_cases/start_narration_use_case.dart';
import 'package:context_app/features/narration/presentation/narration_state.dart';
import 'package:context_app/features/journey/domain/use_cases/save_narration_to_journey_use_case.dart';
import 'package:uuid/uuid.dart';

/// 播放器控制器
///
/// 使用 StateNotifier 管理播放器狀態
/// 負責協調 Use Cases 和 TTS Service
class PlayerController extends StateNotifier<NarrationState> {
  final StartNarrationUseCase _startNarrationUseCase;
  final SaveNarrationToJourneyUseCase _saveNarrationToPassportUseCase;
  final TtsService _ttsService;

  StreamSubscription<void>? _ttsCompleteSubscription;
  StreamSubscription<void>? _ttsStartSubscription;
  StreamSubscription<String>? _ttsErrorSubscription;
  StreamSubscription<TtsProgress>? _ttsProgressSubscription;

  Timer? _progressTimer;

  PlayerController(
    this._startNarrationUseCase,
    this._saveNarrationToPassportUseCase,
    this._ttsService,
  ) : super(NarrationState.initial()) {
    _setupTtsListeners();
  }

  /// 初始化並開始生成導覽
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言代碼（預設為 'zh-TW'）
  Future<void> initialize(
    Place place,
    NarrationAspect aspect, {
    String language = 'zh-TW',
  }) async {
    // 設定為載入中狀態
    state = state.loading();

    try {
      // 使用 StartNarrationUseCase 生成導覽
      final narration = await _startNarrationUseCase.execute(
        place: place,
        aspect: aspect,
        language: language,
      );

      // 更新狀態為就緒
      state = state.ready(narration);
    } on NarrationGenerationException catch (e) {
      state = state.error(e.type, message: e.rawMessage);
    } catch (e) {
      state = state.error(NarrationErrorType.unknown, message: e.toString());
    }
  }

  /// 使用現有內容初始化（用於回放已儲存的導覽）
  Future<void> initializeWithContent(
    Place place,
    NarrationAspect aspect,
    String contentText, {
    String language = 'zh-TW',
  }) async {
    state = state.loading();

    try {
      // 模擬生成過程，實際上直接構建物件
      const uuid = Uuid();
      final narration = Narration.create(
        id: uuid.v4(),
        place: place,
        aspect: aspect,
      );

      final content = NarrationContent.fromText(
        contentText,
        language: language,
      );

      // 初始化 TTS
      await _ttsService.initialize();
      await _ttsService.setLanguage(language);

      final readyNarration = narration.ready(content);

      state = state.ready(readyNarration);
    } catch (e) {
      state = state.error(NarrationErrorType.unknown, message: e.toString());
    }
  }

  /// 儲存導覽到護照
  Future<void> saveToPassport(String userId) async {
    if (state.narration == null) {
      return;
    }

    try {
      await _saveNarrationToPassportUseCase.execute(
        userId: userId,
        narration: state.narration!,
      );
    } catch (e) {
      // 這裡可以選擇透過 state 通知 UI 錯誤，或者拋出異常讓 UI 處理
      // 為了簡單起見，我們暫時不改變 state，但理想情況下應該有 toast 通知
      rethrow;
    }
  }

  /// 設定 TTS 事件監聽器
  void _setupTtsListeners() {
    // 監聽播放完成事件
    _ttsCompleteSubscription = _ttsService.onComplete.listen((_) {
      _stopProgressTimer();
      if (state.narration != null) {
        // 設置到最後一個字符並完成播放
        final totalLength = state.narration!.content?.text.length ?? 0;
        final updatedNarration = state.narration!
            .updateProgress(state.narration!.duration)
            .updateCharPosition(totalLength);
        state = state.updateNarration(updatedNarration);
      }
    });

    // 監聽播放開始事件
    _ttsStartSubscription = _ttsService.onStart.listen((_) {
      _startProgressTimer();
      // 重置字符位置到開頭
      if (state.narration != null) {
        final updatedNarration = state.narration!.updateCharPosition(0);
        state = state.updateNarration(updatedNarration);
      }
    });

    // 監聽錯誤事件
    _ttsErrorSubscription = _ttsService.onError.listen((error) {
      state = state.error(NarrationErrorType.ttsPlaybackError, message: error);
    });

    // 監聽進度事件（字符級別的精確追蹤）
    _ttsProgressSubscription = _ttsService.onProgress.listen((progress) {
      // 使用 TTS 提供的字符級別進度更新段落索引
      if (state.narration != null && state.isPlaying) {
        final updatedNarration = state.narration!.updateCharPosition(
          progress.currentPosition, // 字符位置
        );
        state = state.updateNarration(updatedNarration);
      }
    });
  }

  /// 播放/暫停切換
  void playPause() {
    if (state.narration == null) {
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
      return;
    }

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
      state = state.error(
        NarrationErrorType.ttsPlaybackError,
        message: '播放失敗：$e',
      );
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    if (state.narration == null) {
      return;
    }

    try {
      // 暫停 TTS
      await _ttsService.pause();

      // 更新 Narration 聚合狀態
      final updatedNarration = state.narration!.pause();
      state = state.updateNarration(updatedNarration);

      // 停止進度定時器
      _stopProgressTimer();
    } catch (e) {
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
      return;
    }

    try {
      // 更新 Narration 聚合
      final updatedNarration = seconds > 0
          ? state.narration!.seekForward(seconds)
          : state.narration!.seekBackward(seconds.abs());

      state = state.updateNarration(updatedNarration);

      // 注意：flutter_tts 不支援精確的 seek 操作
      // 需要重新開始播放並跳到指定位置
      // 這是一個簡化實現，實際可能需要更複雜的邏輯
    } catch (e) {
      // Ignore seek errors
    }
  }

  /// 開始進度定時器
  ///
  /// 職責分離：
  /// - 定時器：追蹤播放時間（用於進度條顯示）
  /// - TTS 進度回調：追蹤字符位置（用於段落索引計算）
  void _startProgressTimer() {
    _stopProgressTimer();

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.narration != null && state.isPlaying) {
        final newPosition = state.currentPosition + 1;

        // 更新播放時間進度（用於進度條）
        // 段落索引由 TTS 進度回調的字符位置決定
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
