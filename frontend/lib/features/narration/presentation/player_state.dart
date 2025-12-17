import 'package:context_app/features/narration/presentation/playback_state.dart';

/// 播放器狀態
///
/// 管理音訊播放的運行時狀態
/// 與領域模型 Narration 分離，遵循關注點分離原則
class PlayerState {
  /// 播放狀態
  final PlaybackState state;

  /// 當前播放位置
  final Duration currentPosition;

  /// 音訊總時長（由音訊播放器提供，精確）
  final Duration duration;

  /// TTS 當前播放的字符位置（用於段落同步）
  final int currentCharPosition;

  const PlayerState({
    required this.state,
    this.currentPosition = Duration.zero,
    this.duration = Duration.zero,
    this.currentCharPosition = 0,
  });

  /// 建立初始狀態（載入中）
  factory PlayerState.loading() {
    return const PlayerState(state: PlaybackState.loading);
  }

  /// 建立準備就緒狀態
  factory PlayerState.ready({required Duration duration}) {
    return PlayerState(state: PlaybackState.ready, duration: duration);
  }

  /// 剩餘播放時間
  Duration get remainingTime => duration - currentPosition;

  /// 播放進度（0.0 - 1.0）
  double get progress {
    if (duration.inMilliseconds <= 0) return 0.0;
    return currentPosition.inMilliseconds / duration.inMilliseconds;
  }

  /// 便利狀態檢查
  bool get isPlaying => state == PlaybackState.playing;
  bool get isPaused => state == PlaybackState.paused;
  bool get isLoading => state == PlaybackState.loading;
  bool get isReady => state == PlaybackState.ready;
  bool get isCompleted => state == PlaybackState.completed;
  bool get hasError => state == PlaybackState.error;

  /// 建立副本並更新指定屬性
  PlayerState copyWith({
    PlaybackState? state,
    Duration? currentPosition,
    Duration? duration,
    int? currentCharPosition,
  }) {
    return PlayerState(
      state: state ?? this.state,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      currentCharPosition: currentCharPosition ?? this.currentCharPosition,
    );
  }

  @override
  String toString() {
    return 'PlayerState(state: $state, position: ${currentPosition.inSeconds}s/${duration.inSeconds}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayerState &&
        other.state == state &&
        other.currentPosition == currentPosition &&
        other.duration == duration &&
        other.currentCharPosition == currentCharPosition;
  }

  @override
  int get hashCode {
    return Object.hash(state, currentPosition, duration, currentCharPosition);
  }
}
