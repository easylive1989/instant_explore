import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:context_app/features/analytics/domain/models/consent_state.dart';
import 'package:context_app/features/analytics/domain/services/consent_repository.dart';

/// SharedPreferences keys used by [SharedPrefsConsentRepository].
///
/// Kept as named constants so the analytics provider wiring (and tests)
/// can reference them without redefining string literals.
const String kConsentEnabledKey = 'analytics.consent.enabled';
const String kConsentUpdatedAtKey = 'analytics.consent.updated_at';

/// [ConsentRepository] backed by [SharedPreferences].
///
/// When no consent has ever been written, [read] seeds and returns
/// [ConsentState.defaultOn] (the "consent default ON" product decision).
/// [watch] is a broadcast stream whose first subscriber receives the
/// current persisted state before any writes.
class SharedPrefsConsentRepository implements ConsentRepository {
  SharedPrefsConsentRepository(this._prefs) {
    _controller = StreamController<ConsentState>.broadcast(
      onListen: _emitCurrentState,
    );
  }

  final SharedPreferences _prefs;
  late final StreamController<ConsentState> _controller;

  @override
  Future<ConsentState> read() async {
    if (!_prefs.containsKey(kConsentEnabledKey)) {
      return ConsentState.defaultOn();
    }
    final enabled = _prefs.getBool(kConsentEnabledKey) ?? true;
    final updatedAtMs = _prefs.getInt(kConsentUpdatedAtKey);
    final updatedAt = updatedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs)
        : DateTime.now();
    return ConsentState(enabled: enabled, updatedAt: updatedAt);
  }

  @override
  Future<void> write(ConsentState state) async {
    await _prefs.setBool(kConsentEnabledKey, state.enabled);
    await _prefs.setInt(
      kConsentUpdatedAtKey,
      state.updatedAt.millisecondsSinceEpoch,
    );
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  @override
  Stream<ConsentState> watch() => _controller.stream;

  /// Closes the broadcast controller.
  ///
  /// Call this when the owning provider is disposed. Safe to call more
  /// than once.
  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  Future<void> _emitCurrentState() async {
    final state = await read();
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }
}
