import 'package:context_app/features/player/models/narration.dart';
import 'package:context_app/features/player/models/playback_state.dart';

/// 播放器狀態
///
/// 封裝播放器 UI 所需的所有狀態資訊
class PlayerState {
  /// 當前導覽聚合
  final Narration? narration;

  /// 播放狀態
  final PlaybackState playbackState;

  /// 當前播放位置（秒）
  final int currentPosition;

  /// 總時長（秒）
  final int duration;

  /// 錯誤訊息
  final String? errorMessage;

  const PlayerState({
    this.narration,
    this.playbackState = PlaybackState.loading,
    this.currentPosition = 0,
    this.duration = 0,
    this.errorMessage,
  });

  /// 建立初始狀態
  factory PlayerState.initial() {
    return const PlayerState();
  }

  /// 建立載入中狀態
  PlayerState loading() {
    return copyWith(playbackState: PlaybackState.loading, errorMessage: null);
  }

  /// 建立就緒狀態
  PlayerState ready(Narration narration) {
    return copyWith(
      narration: narration,
      playbackState: PlaybackState.ready,
      duration: narration.duration,
      currentPosition: 0,
      errorMessage: null,
    );
  }

  /// 建立播放中狀態
  PlayerState playing() {
    return copyWith(playbackState: PlaybackState.playing);
  }

  /// 建立暫停狀態
  PlayerState paused() {
    return copyWith(playbackState: PlaybackState.paused);
  }

  /// 建立完成狀態
  PlayerState completed() {
    return copyWith(
      playbackState: PlaybackState.completed,
      currentPosition: duration,
    );
  }

  /// 建立錯誤狀態
  PlayerState error(String message) {
    return copyWith(playbackState: PlaybackState.error, errorMessage: message);
  }

  /// 更新播放進度
  PlayerState updateProgress(int position) {
    return copyWith(
      currentPosition: position,
      playbackState: position >= duration
          ? PlaybackState.completed
          : playbackState,
    );
  }

  /// 更新導覽聚合
  PlayerState updateNarration(Narration narration) {
    return copyWith(
      narration: narration,
      playbackState: narration.state,
      currentPosition: narration.currentPosition,
      duration: narration.duration,
      errorMessage: narration.errorMessage,
    );
  }

  /// 建立副本並更新指定屬性
  PlayerState copyWith({
    Narration? narration,
    PlaybackState? playbackState,
    int? currentPosition,
    int? duration,
    String? errorMessage,
  }) {
    return PlayerState(
      narration: narration ?? this.narration,
      playbackState: playbackState ?? this.playbackState,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 是否正在播放
  bool get isPlaying => playbackState == PlaybackState.playing;

  /// 是否暫停中
  bool get isPaused => playbackState == PlaybackState.paused;

  /// 是否載入中
  bool get isLoading => playbackState == PlaybackState.loading;

  /// 是否就緒
  bool get isReady => playbackState == PlaybackState.ready;

  /// 是否完成
  bool get isCompleted => playbackState == PlaybackState.completed;

  /// 是否有錯誤
  bool get hasError => playbackState == PlaybackState.error;

  /// 播放進度百分比 (0.0 - 1.0)
  double get progress {
    if (duration == 0) return 0.0;
    return currentPosition / duration;
  }

  /// 當前段落索引
  int? get currentSegmentIndex {
    return narration?.getCurrentSegmentIndex();
  }

  @override
  String toString() {
    return 'PlayerState(state: $playbackState, '
        'position: $currentPosition/$duration, '
        'narration: ${narration?.id})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayerState &&
        other.narration == narration &&
        other.playbackState == playbackState &&
        other.currentPosition == currentPosition &&
        other.duration == duration &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      narration,
      playbackState,
      currentPosition,
      duration,
      errorMessage,
    );
  }
}
