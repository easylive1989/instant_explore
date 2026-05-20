/// Why a narration playback ended without reaching the completion
/// threshold (see Story 1 AC3, default >= 95%).
///
/// Values are persisted by their [wireName] (snake_case), so renaming an
/// existing member is a breaking change for any downstream consumer.
enum AbandonReason {
  /// The user explicitly stopped playback (tap pause / stop / close).
  userStop,

  /// The user switched to a different narration before this one ended.
  switched,

  /// The app went to background and playback was paused/torn down.
  backgrounded,

  /// The OS killed the app while playback was active; the abandoned
  /// event is replayed on the next launch.
  killed,

  /// Navigation moved away from the narration screen.
  routeChange;

  /// Wire-format identifier (snake_case).
  String get wireName {
    switch (this) {
      case AbandonReason.userStop:
        return 'user_stop';
      case AbandonReason.switched:
        return 'switched';
      case AbandonReason.backgrounded:
        return 'backgrounded';
      case AbandonReason.killed:
        return 'killed';
      case AbandonReason.routeChange:
        return 'route_change';
    }
  }
}
