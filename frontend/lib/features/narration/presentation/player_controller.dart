import 'dart:async';
import 'package:context_app/features/narration/domain/models/narration_content_exception.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/services/narration_service_exception.dart';
import 'package:context_app/features/narration/domain/services/narration_service_error_type.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/narration_state.dart';
import 'package:context_app/features/narration/presentation/narration_state_error_type.dart';
import 'package:context_app/features/journey/domain/use_cases/save_narration_to_journey_use_case.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 播放器控制器
///
/// 使用 StateNotifier 管理播放器狀態
/// 負責協調 Use Cases 和 TTS Service
class PlayerController extends StateNotifier<NarrationState> {
  final CreateNarrationUseCase _createNarrationUseCase;
  final SaveNarrationToJourneyUseCase _saveNarrationToJourneyUseCase;
  final TtsService _ttsService;

  StreamSubscription<void>? _ttsCompleteSubscription;
  StreamSubscription<void>? _ttsStartSubscription;
  StreamSubscription<String>? _ttsErrorSubscription;
  StreamSubscription<TtsProgress>? _ttsProgressSubscription;

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
    } on NarrationServiceException catch (e) {
      // 處理 AI 服務相關錯誤
      state = state.error(_mapServiceErrorType(e.type), message: e.rawMessage);
    } on NarrationContentException catch (e) {
      // 處理內容驗證錯誤
      state = state.error(
        NarrationStateErrorType.contentGenerationFailed,
        message: e.rawMessage,
      );
    } catch (e) {
      state = state.error(
        NarrationStateErrorType.unknown,
        message: e.toString(),
      );
    }
  }

  /// 將 NarrationServiceErrorType 轉換為 NarrationStateErrorType
  NarrationStateErrorType _mapServiceErrorType(NarrationServiceErrorType type) {
    switch (type) {
      case NarrationServiceErrorType.aiQuotaExceeded:
        return NarrationStateErrorType.aiQuotaExceeded;
      case NarrationServiceErrorType.networkError:
        return NarrationStateErrorType.networkError;
      case NarrationServiceErrorType.configurationError:
        return NarrationStateErrorType.configurationError;
      case NarrationServiceErrorType.serverError:
        return NarrationStateErrorType.serverError;
      case NarrationServiceErrorType.unsupportedLocation:
        return NarrationStateErrorType.unsupportedLocation;
      case NarrationServiceErrorType.unknown:
        return NarrationStateErrorType.unknown;
    }
  }

  /// 使用現有內容初始化（用於回放已儲存的導覽）
  Future<void> initializeWithContent(
    Place place,
    NarrationContent content,
  ) async {
    state = state.loading();

    try {
      // 初始化 TtsService
      await _ttsService.initialize();
      await _ttsService.setLanguage(content.language);

      // 更新狀態為就緒（aspect 為 null 因為是回放模式）
      state = state.ready(place, null, content);
    } on NarrationContentException catch (e) {
      state = state.error(
        NarrationStateErrorType.contentGenerationFailed,
        message: e.rawMessage,
      );
    } catch (e) {
      state = state.error(
        NarrationStateErrorType.unknown,
        message: e.toString(),
      );
    }
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
      if (state.content != null) {
        // 設置到最後一個字符並完成播放
        final totalLength = state.content!.text.length;
        state = state.updateCharPosition(totalLength).completed();
      }
    });

    // 監聽播放開始事件
    _ttsStartSubscription = _ttsService.onStart.listen((_) {
      // 重置字符位置到開頭
      state = state.updateCharPosition(0);
    });

    // 監聽錯誤事件
    _ttsErrorSubscription = _ttsService.onError.listen((error) {
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: error,
      );
    });

    // 監聽進度事件（字符級別的精確追蹤）
    _ttsProgressSubscription = _ttsService.onProgress.listen((progress) {
      // 使用 TTS 提供的字符級別進度更新段落索引和進度
      if (state.content != null && state.isPlaying) {
        state = state.updateCharPosition(progress.currentPosition);
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

    try {
      // 如果是從完成狀態重新播放，需要從頭開始
      if (state.isCompleted) {
        await _ttsService.stop();
      }

      // 播放 TTS
      final success = await _ttsService.speak(state.content!.text);

      if (success) {
        // 更新狀態為播放中
        state = state.playing();
      } else {
        state = state.error(
          NarrationStateErrorType.ttsPlaybackError,
          message: '播放失敗',
        );
      }
    } catch (e) {
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: '播放失敗：$e',
      );
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    if (state.content == null) {
      return;
    }

    try {
      // 暫停 TTS
      await _ttsService.pause();

      // 更新狀態為暫停
      state = state.paused();
    } catch (e) {
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: '暫停失敗：$e',
      );
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
