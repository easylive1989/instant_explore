import 'package:context_app/features/narration/presentation/playback_state.dart';

/// 播放器狀態
///
/// 管理音訊播放的運行時狀態
/// 與領域模型 Narration 分離，遵循關注點分離原則
class PlayerState {
  /// 播放狀態
  final PlaybackState state;

  /// TTS 當前播放的字符位置（用於段落同步和進度計算）
  final int currentCharPosition;

  const PlayerState({required this.state, this.currentCharPosition = 0});

  /// 建立初始狀態（載入中）
  factory PlayerState.loading() {
    return const PlayerState(state: PlaybackState.loading);
  }

  /// 建立準備就緒狀態
  factory PlayerState.ready() {
    return const PlayerState(state: PlaybackState.ready);
  }

  /// 便利狀態檢查
  bool get isPlaying => state == PlaybackState.playing;
  bool get isPaused => state == PlaybackState.paused;
  bool get isLoading => state == PlaybackState.loading;
  bool get isReady => state == PlaybackState.ready;
  bool get isCompleted => state == PlaybackState.completed;
  bool get hasError => state == PlaybackState.error;

  /// 建立副本並更新指定屬性
  PlayerState copyWith({PlaybackState? state, int? currentCharPosition}) {
    return PlayerState(
      state: state ?? this.state,
      currentCharPosition: currentCharPosition ?? this.currentCharPosition,
    );
  }

  @override
  String toString() {
    return 'PlayerState(state: $state, charPosition: $currentCharPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayerState &&
        other.state == state &&
        other.currentCharPosition == currentCharPosition;
  }

  @override
  int get hashCode {
    return Object.hash(state, currentCharPosition);
  }
}
