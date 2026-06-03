import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state_error_type.dart';
import 'package:context_app/features/narration/presentation/controllers/playback_state.dart';
import 'package:context_app/features/narration/presentation/controllers/player_state.dart';
import 'package:equatable/equatable.dart';

/// 哨兵物件，用於區分「未傳入」與「明確傳入 null」。
const Object _unset = Object();

/// 導覽播放狀態
///
/// 聚合導覽內容和播放狀態
/// 封裝播放器 UI 所需的所有狀態資訊
class NarrationState extends Equatable {
  final Place? place;
  final NarrationContent? content;

  /// 播放器狀態（播放運行時狀態）
  final PlayerState playerState;

  /// 錯誤類型（當 playerState.state 為 error 時）
  final NarrationStateErrorType? errorType;

  /// 錯誤訊息（可選，用於 debug 或顯示額外資訊）
  final String? errorMessage;

  const NarrationState({
    this.place,
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
    return copyWith(
      playerState: PlayerState.loading(),
      errorType: null,
      errorMessage: null,
    );
  }

  /// 建立就緒狀態
  NarrationState ready(Place place, NarrationContent content) {
    return copyWith(
      place: place,
      content: content,
      playerState: PlayerState.ready(),
      errorType: null,
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
        currentCharPosition: content?.text.length ?? 0,
      ),
    );
  }

  /// 建立錯誤狀態
  NarrationState error(NarrationStateErrorType type, {String? message}) {
    return copyWith(
      playerState: playerState.copyWith(state: PlaybackState.error),
      errorType: type,
      errorMessage: message,
    );
  }

  /// 更新字符位置（用於段落同步和進度計算）
  NarrationState updateCharPosition(int charPosition) {
    final totalChars = content?.text.length ?? 0;
    final isComplete = totalChars > 0 && charPosition >= totalChars;

    return copyWith(
      playerState: playerState.copyWith(
        currentCharPosition: charPosition,
        state: isComplete ? PlaybackState.completed : playerState.state,
      ),
    );
  }

  /// 建立副本並更新指定屬性
  NarrationState copyWith({
    Place? place,
    NarrationContent? content,
    PlayerState? playerState,
    Object? errorType = _unset,
    Object? errorMessage = _unset,
  }) {
    return NarrationState(
      place: place ?? this.place,
      content: content ?? this.content,
      playerState: playerState ?? this.playerState,
      errorType: errorType == _unset
          ? this.errorType
          : errorType as NarrationStateErrorType?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get isPlaying => playerState.isPlaying;
  bool get isPaused => playerState.isPaused;
  bool get isLoading => playerState.isLoading;
  bool get isReady => playerState.isReady;
  bool get isCompleted => playerState.isCompleted;
  bool get hasError => playerState.hasError;

  double get progress {
    if (content == null) return 0.0;
    final totalChars = content!.text.length;
    if (totalChars == 0) return 0.0;
    return (playerState.currentCharPosition / totalChars).clamp(0.0, 1.0);
  }

  int? get currentSegmentIndex {
    if (content == null) return null;
    return content!.getSegmentIndexByCharPosition(
      playerState.currentCharPosition,
    );
  }

  bool get canSkipNext {
    if (content == null) return false;
    final currentIndex = currentSegmentIndex ?? 0;
    return currentIndex < content!.segments.length - 1;
  }

  bool get canSkipPrevious {
    if (content == null) return false;
    final currentIndex = currentSegmentIndex ?? 0;
    return currentIndex > 0;
  }

  @override
  List<Object?> get props => [
    place,
    content,
    playerState,
    errorType,
    errorMessage,
  ];
}
