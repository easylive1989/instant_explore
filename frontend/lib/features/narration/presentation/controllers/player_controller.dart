import 'dart:async';
import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/core/errors/app_error_type.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/subscription/domain/errors/subscription_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state_error_type.dart';
import 'package:context_app/features/journey/domain/use_cases/save_narration_to_journey_use_case.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 播放器控制器
///
/// 使用 StateNotifier 管理播放器狀態
/// 負責協調 Use Cases 和 TTS Service
/// 注意：權益檢查由 CreateNarrationUseCase 處理
class PlayerController extends StateNotifier<NarrationState> {
  final CreateNarrationUseCase _createNarrationUseCase;
  final SaveNarrationToJourneyUseCase _saveNarrationToJourneyUseCase;
  final TtsService _ttsService;

  StreamSubscription<void>? _ttsCompleteSubscription;
  StreamSubscription<void>? _ttsStartSubscription;
  StreamSubscription<String>? _ttsErrorSubscription;
  StreamSubscription<TtsProgress>? _ttsProgressSubscription;

  /// 字符位置偏移量（當從中間段落開始播放時使用）
  /// 因為 TTS 只能播放完整文本，跳段時需要從目標位置截取子字串播放
  /// 此偏移量用於將 TTS 的進度轉換回原始文本的位置
  int _charPositionOffset = 0;

  /// 是否正在執行跳段操作
  /// 用於防止 onComplete 事件在跳段時誤觸
  bool _isSkipping = false;

  PlayerController(
    this._createNarrationUseCase,
    this._saveNarrationToJourneyUseCase,
    this._ttsService,
  ) : super(NarrationState.initial()) {
    _setupTtsListeners();
  }

  /// 初始化並開始生成導覽
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言（預設為繁體中文）
  Future<void> initialize(
    Place place,
    NarrationAspect aspect, {
    required Language language,
  }) async {
    // 設定為載入中狀態
    state = state.loading();

    try {
      // 使用 CreateNarrationUseCase 生成導覽內容
      // Use Case 會處理權益檢查和消耗免費額度
      final content = await _createNarrationUseCase.execute(
        place: place,
        aspect: aspect,
        language: language,
      );

      // 初始化 TtsService
      await _ttsService.initialize();
      await _ttsService.setLanguage(language);

      // 更新狀態為就緒
      state = state.ready(place, aspect, content);
    } on AppError catch (e) {
      final stateErrorType = _mapAppErrorToStateError(e.type);
      state = state.error(stateErrorType, message: e.message);
    }
  }

  /// 將 AppErrorType 轉換為 NarrationStateErrorType
  NarrationStateErrorType _mapAppErrorToStateError(AppErrorType type) {
    // Narration 相關錯誤
    if (type is NarrationError) {
      switch (type) {
        case NarrationError.freeQuotaExceeded:
          return NarrationStateErrorType.freeQuotaExceeded;
        case NarrationError.networkError:
          return NarrationStateErrorType.networkError;
        case NarrationError.configurationError:
          return NarrationStateErrorType.configurationError;
        case NarrationError.serverError:
          return NarrationStateErrorType.serverError;
        case NarrationError.unsupportedLocation:
          return NarrationStateErrorType.unsupportedLocation;
        case NarrationError.contentGenerationFailed:
          return NarrationStateErrorType.contentGenerationFailed;
        case NarrationError.ttsPlaybackError:
          return NarrationStateErrorType.ttsPlaybackError;
        case NarrationError.unknown:
          return NarrationStateErrorType.unknown;
      }
    }

    // Subscription 相關錯誤
    if (type is SubscriptionError) {
      switch (type) {
        case SubscriptionError.freeQuotaExceeded:
          return NarrationStateErrorType.freeQuotaExceeded;
        default:
          return NarrationStateErrorType.unknown;
      }
    }

    // 其他類型一律返回 unknown
    return NarrationStateErrorType.unknown;
  }

  /// 使用現有內容初始化（用於回放已儲存的導覽）
  Future<void> initializeWithContent(
    Place place,
    NarrationContent content,
  ) async {
    state = state.loading();

    // 初始化 TtsService
    await _ttsService.initialize();
    await _ttsService.setLanguage(content.language);

    // 更新狀態為就緒（aspect 為 null 因為是回放模式）
    state = state.ready(place, null, content);
  }

  /// 儲存導覽到歷程
  Future<void> saveToJourney(
    String userId, {
    required Language language,
  }) async {
    if (state.content == null || state.place == null || state.aspect == null) {
      return;
    }

    try {
      // 直接傳遞個別參數給 use case
      await _saveNarrationToJourneyUseCase.execute(
        userId: userId,
        place: state.place!,
        aspect: state.aspect!,
        content: state.content!,
        language: language,
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
      // 如果正在跳段，忽略此事件（stop() 觸發的 complete 不算真正完成）
      if (_isSkipping) return;

      if (state.content != null) {
        // 設置到最後一個字符並完成播放
        final totalLength = state.content!.text.length;
        state = state.updateCharPosition(totalLength).completed();
      }
    });

    // 監聽播放開始事件
    _ttsStartSubscription = _ttsService.onStart.listen((_) {
      // 新播放真正開始後，重置跳段標誌
      // 這樣可以確保 stop() 觸發的非同步 onComplete 不會影響狀態
      _isSkipping = false;
      // 根據偏移量設定字符位置（跳段播放時偏移量不為 0）
      state = state.updateCharPosition(_charPositionOffset);
    });

    // 監聯錯誤事件
    _ttsErrorSubscription = _ttsService.onError.listen((error) {
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: error,
      );
    });

    // 監聽進度事件（字符級別的精確追蹤）
    _ttsProgressSubscription = _ttsService.onProgress.listen((progress) {
      // 使用 TTS 提供的字符級別進度更新段落索引和進度
      // 加入偏移量以對應原始文本的實際位置（跳段播放時需要）
      if (state.content != null && state.isPlaying) {
        state = state.updateCharPosition(
          progress.currentPosition + _charPositionOffset,
        );
      }
    });
  }

  /// 播放/暫停切換
  void playPause() {
    if (state.content == null) {
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
    if (state.content == null) {
      return;
    }

    final currentPos = state.playerState.currentCharPosition;
    final isResuming = state.isPaused && currentPos > 0;

    // 如果是從完成狀態重新播放，需要從頭開始
    if (state.isCompleted) {
      await _ttsService.stop();
    }

    String textToPlay;
    if (isResuming) {
      // 從暫停位置恢復播放：截取當前位置到結尾的文本
      _charPositionOffset = currentPos;
      textToPlay = state.content!.text.substring(currentPos);
    } else {
      // 從頭開始播放（就緒或完成狀態）
      _charPositionOffset = 0;
      textToPlay = state.content!.text;
    }

    // 播放 TTS
    final success = await _ttsService.speak(textToPlay);

    if (success) {
      // 更新狀態為播放中
      state = state.playing();
    } else {
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: '播放失敗',
      );
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    if (state.content == null) {
      return;
    }

    // 暫停 TTS
    await _ttsService.pause();

    // 更新狀態為暫停
    state = state.paused();
  }

  /// 跳到指定段落並開始播放
  ///
  /// [segmentIndex] 目標段落索引
  /// 會自動開始播放從目標段落到結尾的內容
  Future<void> skipToSegment(int segmentIndex) async {
    if (state.content == null) return;

    final segments = state.content!.segments;
    if (segmentIndex < 0 || segmentIndex >= segments.length) return;

    // 記錄跳段前的狀態
    final wasPaused = state.isPaused;

    // 設定跳段標誌，防止 onComplete 事件誤觸
    _isSkipping = true;

    // 取得目標段落的起始位置
    final targetSegment = segments[segmentIndex];
    final startPosition = targetSegment.startPosition;

    // 停止目前播放
    await _ttsService.stop();

    // 在 iOS 上，TTS 引擎需要一點時間來完全重置狀態
    // 特別是從暫停狀態轉換時
    if (wasPaused) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    // 設定偏移量（用於 TTS 進度轉換）
    _charPositionOffset = startPosition;

    // 更新狀態為目標位置，保持播放狀態
    state = state.updateCharPosition(startPosition).playing();

    // 擷取從目標段落到結尾的文本
    final textToPlay = state.content!.text.substring(startPosition);

    // 開始播放（onStart 會重置 _isSkipping）
    final success = await _ttsService.speak(textToPlay);
    if (!success) {
      // 播放失敗時手動重置 flag
      _isSkipping = false;
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: '跳段播放失敗',
      );
    }
  }

  /// 跳到下一段
  ///
  /// 如果已是最後一段則不執行
  Future<void> skipToNextSegment() async {
    if (state.content == null) return;

    final currentIndex = state.currentSegmentIndex ?? 0;
    final nextIndex = currentIndex + 1;

    if (nextIndex < state.content!.segments.length) {
      await skipToSegment(nextIndex);
    }
  }

  /// 跳到上一段
  ///
  /// 如果已是第一段則不執行
  Future<void> skipToPreviousSegment() async {
    if (state.content == null) return;

    final currentIndex = state.currentSegmentIndex ?? 0;
    final previousIndex = currentIndex - 1;

    if (previousIndex >= 0) {
      await skipToSegment(previousIndex);
    }
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

    super.dispose();
  }
}
