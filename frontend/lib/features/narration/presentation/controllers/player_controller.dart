import 'dart:async';
import 'package:context_app/features/narration/presentation/controllers/narration_state_error_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/narration/data/tts_service.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
import 'package:context_app/features/narration/presentation/controllers/player_state.dart';

/// 播放器控制器
///
/// 使用 StateNotifier 管理播放器狀態
/// 僅負責播放控制，不負責生成導覽內容
class PlayerController extends StateNotifier<NarrationState> {
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

  PlayerController(this._ttsService) : super(NarrationState.initial()) {
    _setupTtsListeners();
  }

  /// 使用現有內容初始化（用於播放已生成的導覽）
  Future<void> initializeWithContent(
    Place place,
    NarrationContent content,
  ) async {
    // 立即顯示內容，TTS 初始化期間播放鈕暫時停用
    state = NarrationState(
      place: place,
      content: content,
      playerState: PlayerState.loading(),
    );

    // 初始化 TtsService
    await _ttsService.initialize();
    await _ttsService.setLanguage(content.language);

    // 更新狀態為就緒
    state = state.ready(place, null, content);
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
      _isSkipping = false;
      // 根據偏移量設定字符位置（跳段播放時偏移量不為 0）
      state = state.updateCharPosition(_charPositionOffset);
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

    final String textToPlay;
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

    await _ttsService.pause();
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
      _isSkipping = false;
      state = state.error(
        NarrationStateErrorType.ttsPlaybackError,
        message: '跳段播放失敗',
      );
    }
  }

  /// 跳到下一段
  Future<void> skipToNextSegment() async {
    if (state.content == null) return;

    final currentIndex = state.currentSegmentIndex ?? 0;
    final nextIndex = currentIndex + 1;

    if (nextIndex < state.content!.segments.length) {
      await skipToSegment(nextIndex);
    }
  }

  /// 跳到上一段
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
    _ttsService.stop();

    _ttsCompleteSubscription?.cancel();
    _ttsStartSubscription?.cancel();
    _ttsErrorSubscription?.cancel();
    _ttsProgressSubscription?.cancel();

    super.dispose();
  }
}
