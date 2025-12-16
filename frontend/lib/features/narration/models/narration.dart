import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/narration/models/narration_aspect.dart';
import 'package:context_app/features/narration/models/narration_content.dart';
import 'package:context_app/features/narration/models/playback_state.dart';

/// 導覽聚合根
///
/// 代表一次完整的語音導覽，包含所有必要的狀態和行為
/// 遵循 DDD 聚合根原則，封裝業務邏輯
class Narration {
  /// 唯一識別碼
  final String id;

  /// 地點資訊
  final Place place;

  /// 導覽介紹面向
  final NarrationAspect aspect;

  /// 導覽內容
  final NarrationContent? content;

  /// 播放狀態
  final PlaybackState state;

  /// 當前播放位置（秒）
  final int currentPosition;

  /// TTS 當前播放的字符位置
  final int currentCharPosition;

  /// 總時長（秒）
  final int duration;

  /// 錯誤訊息（當 state 為 error 時）
  final String? errorMessage;

  const Narration({
    required this.id,
    required this.place,
    required this.aspect,
    this.content,
    required this.state,
    this.currentPosition = 0,
    this.currentCharPosition = 0,
    this.duration = 0,
    this.errorMessage,
  });

  /// 建立新的導覽實例（初始狀態：loading）
  factory Narration.create({
    required String id,
    required Place place,
    required NarrationAspect aspect,
  }) {
    return Narration(
      id: id,
      place: place,
      aspect: aspect,
      state: PlaybackState.loading,
    );
  }

  /// 載入完成，進入準備就緒狀態
  Narration ready(NarrationContent content) {
    return copyWith(
      content: content,
      state: PlaybackState.ready,
      duration: content.estimatedDuration,
    );
  }

  /// 開始播放
  Narration play() {
    // 業務規則：只有在 ready、paused 或 completed 狀態才能播放
    if (state == PlaybackState.ready ||
        state == PlaybackState.paused ||
        state == PlaybackState.completed) {
      return copyWith(
        state: PlaybackState.playing,
        // 如果是播放完成後重新播放，重置到開頭
        currentPosition: state == PlaybackState.completed ? 0 : currentPosition,
        currentCharPosition: state == PlaybackState.completed
            ? 0
            : currentCharPosition,
      );
    }
    return this;
  }

  /// 暫停播放
  Narration pause() {
    // 業務規則：只有在 playing 狀態才能暫停
    if (state == PlaybackState.playing) {
      return copyWith(state: PlaybackState.paused);
    }
    return this;
  }

  /// 快進指定秒數
  Narration seekForward(int seconds) {
    // 業務規則：只有在 ready、playing、paused 狀態才能快進
    if (state == PlaybackState.ready ||
        state == PlaybackState.playing ||
        state == PlaybackState.paused) {
      final newPosition = (currentPosition + seconds).clamp(0, duration);
      return copyWith(currentPosition: newPosition);
    }
    return this;
  }

  /// 快退指定秒數
  Narration seekBackward(int seconds) {
    // 業務規則：只有在 ready、playing、paused 狀態才能快退
    if (state == PlaybackState.ready ||
        state == PlaybackState.playing ||
        state == PlaybackState.paused) {
      final newPosition = (currentPosition - seconds).clamp(0, duration);
      return copyWith(currentPosition: newPosition);
    }
    return this;
  }

  /// 更新播放進度
  Narration updateProgress(int position) {
    // 業務規則：只有在 playing 狀態才更新進度
    if (state == PlaybackState.playing) {
      // 檢查是否播放完成
      if (position >= duration) {
        return copyWith(
          currentPosition: duration,
          state: PlaybackState.completed,
        );
      }
      return copyWith(currentPosition: position);
    }
    return this;
  }

  /// 更新 TTS 播放的字符位置
  ///
  /// [charPosition] 當前播放到的字符位置
  /// 返回更新後的 Narration 實例
  Narration updateCharPosition(int charPosition) {
    // 業務規則：只有在 playing 狀態才更新字符位置
    if (state == PlaybackState.playing) {
      return copyWith(currentCharPosition: charPosition);
    }
    return this;
  }

  /// 發生錯誤
  Narration error(String message) {
    return copyWith(state: PlaybackState.error, errorMessage: message);
  }

  /// 取得當前應該高亮的段落索引
  ///
  /// 如果沒有內容或尚未開始播放，返回 null
  /// 使用字符位置來計算段落索引，提供更精確的同步
  int? getCurrentSegmentIndex() {
    if (content == null || state == PlaybackState.loading) {
      return null;
    }
    // 使用字符位置計算（精確）
    return content!.getSegmentIndexByCharPosition(currentCharPosition);
  }

  /// 建立副本並更新指定屬性
  Narration copyWith({
    String? id,
    Place? place,
    NarrationAspect? aspect,
    NarrationContent? content,
    PlaybackState? state,
    int? currentPosition,
    int? currentCharPosition,
    int? duration,
    String? errorMessage,
  }) {
    return Narration(
      id: id ?? this.id,
      place: place ?? this.place,
      aspect: aspect ?? this.aspect,
      content: content ?? this.content,
      state: state ?? this.state,
      currentPosition: currentPosition ?? this.currentPosition,
      currentCharPosition: currentCharPosition ?? this.currentCharPosition,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'Narration(id: $id, place: ${place.name}, aspect: $aspect, '
        'state: $state, position: $currentPosition/$duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Narration &&
        other.id == id &&
        other.place == place &&
        other.aspect == aspect &&
        other.content == content &&
        other.state == state &&
        other.currentPosition == currentPosition &&
        other.currentCharPosition == currentCharPosition &&
        other.duration == duration &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      place,
      aspect,
      content,
      state,
      currentPosition,
      currentCharPosition,
      duration,
      errorMessage,
    );
  }
}
