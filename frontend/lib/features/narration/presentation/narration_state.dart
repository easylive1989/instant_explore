import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_error_type.dart';
import 'package:context_app/features/narration/presentation/playback_state.dart';
import 'package:context_app/features/narration/presentation/player_state.dart';

/// 導覽播放狀態
///
/// 聚合導覽內容和播放狀態
/// 封裝播放器 UI 所需的所有狀態資訊
class NarrationState {
  // Replace the aggregated Narration object with flattened fields or necessary components
  final Place? place;
  final NarrationAspect? aspect;
  final NarrationContent? content;

  /// 播放器狀態（播放運行時狀態）
  final PlayerState playerState;

  /// 錯誤類型（當 playerState.state 為 error 時）
  final NarrationErrorType? errorType;

  /// 錯誤訊息（可選，用於 debug 或顯示額外資訊）
  final String? errorMessage;

  const NarrationState({
    this.place,
    this.aspect,
    this.content,
    required this.playerState,
    this.errorType,
    this.errorMessage,
  });

  /// 建立初始狀態
  factory NarrationState.initial() {
    return NarrationState(playerState: PlayerState.loading());
  }

  /// 建立載入中狀態
  NarrationState loading() {
    return copyWith(playerState: PlayerState.loading(), errorMessage: null);
  }

  /// 建立就緒狀態
  NarrationState ready(
    Place place,
    NarrationAspect aspect,
    NarrationContent content, {
    required Duration duration,
  }) {
    return copyWith(
      place: place,
      aspect: aspect,
      content: content,
      playerState: PlayerState.ready(duration: duration),
      errorMessage: null,
    );
  }

  /// 建立播放中狀態
  NarrationState playing() {
    return copyWith(
      playerState: playerState.copyWith(state: PlaybackState.playing),
    );
  }

  /// 建立暫停狀態
  NarrationState paused() {
    return copyWith(
      playerState: playerState.copyWith(state: PlaybackState.paused),
    );
  }

  /// 建立完成狀態
  NarrationState completed() {
    return copyWith(
      playerState: playerState.copyWith(
        state: PlaybackState.completed,
        currentPosition: playerState.duration,
      ),
    );
  }

  /// 建立錯誤狀態
  NarrationState error(NarrationErrorType type, {String? message}) {
    return copyWith(
      playerState: playerState.copyWith(state: PlaybackState.error),
      errorType: type,
      errorMessage: message,
    );
  }

  /// 更新播放進度
  NarrationState updateProgress(Duration position) {
    // 檢查是否播放完成
    final isComplete = position >= playerState.duration;
    return copyWith(
      playerState: playerState.copyWith(
        currentPosition: position,
        state: isComplete ? PlaybackState.completed : playerState.state,
      ),
    );
  }

  /// 更新字符位置（用於段落同步）
  NarrationState updateCharPosition(int charPosition) {
    return copyWith(
      playerState: playerState.copyWith(currentCharPosition: charPosition),
    );
  }

  /// 建立副本並更新指定屬性
  NarrationState copyWith({
    Place? place,
    NarrationAspect? aspect,
    NarrationContent? content,
    PlayerState? playerState,
    NarrationErrorType? errorType,
    String? errorMessage,
  }) {
    return NarrationState(
      place: place ?? this.place,
      aspect: aspect ?? this.aspect,
      content: content ?? this.content,
      playerState: playerState ?? this.playerState,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 是否正在播放
  bool get isPlaying => playerState.isPlaying;

  /// 是否暫停中
  bool get isPaused => playerState.isPaused;

  /// 是否載入中
  bool get isLoading => playerState.isLoading;

  /// 是否就緒
  bool get isReady => playerState.isReady;

  /// 是否完成
  bool get isCompleted => playerState.isCompleted;

  /// 是否有錯誤
  bool get hasError => playerState.hasError;

  /// 播放進度百分比 (0.0 - 1.0)
  /// 基於已播放的文字量計算
  double get progress {
    if (content == null) return 0.0;
    final totalChars = content!.text.length;
    if (totalChars == 0) return 0.0;
    return (playerState.currentCharPosition / totalChars).clamp(0.0, 1.0);
  }

  /// 當前播放位置（秒）
  int get currentPositionSeconds => playerState.currentPosition.inSeconds;

  /// 總時長（秒）
  int get durationSeconds => playerState.duration.inSeconds;

  /// 當前段落索引（用於高亮顯示）
  int? get currentSegmentIndex {
    if (content == null) return null;
    return content!.getSegmentIndexByCharPosition(
      playerState.currentCharPosition,
    );
  }

  @override
  String toString() {
    return 'NarrationState(playerState: $playerState, '
        'place: ${place?.name}, aspect: $aspect, '
        'hasError: $hasError)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NarrationState &&
        other.place == place &&
        other.aspect == aspect &&
        other.content == content &&
        other.playerState == playerState &&
        other.errorType == errorType &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      place,
      aspect,
      content,
      playerState,
      errorType,
      errorMessage,
    );
  }
}
