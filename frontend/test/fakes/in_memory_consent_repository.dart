import 'dart:async';

import 'package:context_app/features/analytics/domain/models/consent_state.dart';
import 'package:context_app/features/analytics/domain/services/consent_repository.dart';

/// In-memory [ConsentRepository] for widget/unit tests.
///
/// Tracks the most-recent state, exposes a counter for `write` calls so
/// tests can assert that toggling the Settings switch reaches the
/// repository, and emits updates on a broadcast stream so widgets
/// rebuild when the consent flag changes.
class InMemoryConsentRepository implements ConsentRepository {
  InMemoryConsentRepository({ConsentState? initial})
    : _state =
          initial ?? ConsentState(enabled: true, updatedAt: DateTime(2026)) {
    _controller = StreamController<ConsentState>.broadcast(
      onListen: () {
        // Schedule the seed emission via a microtask so the listener
        // is fully wired up before the controller adds the event;
        // synchronous `add` from inside `onListen` is silently dropped
        // for broadcast streams.
        scheduleMicrotask(() {
          if (!_controller.isClosed) {
            _controller.add(_state);
          }
        });
      },
    );
  }

  ConsentState _state;
  late final StreamController<ConsentState> _controller;
  final List<ConsentState> writes = <ConsentState>[];

  int get writeCount => writes.length;

  @override
  Future<ConsentState> read() async => _state;

  @override
  Future<void> write(ConsentState state) async {
    _state = state;
    writes.add(state);
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  @override
  Stream<ConsentState> watch() => _controller.stream;

  /// Pushes [state] through the stream without going through [write], so
  /// tests can simulate "consent changed elsewhere" scenarios.
  void emit(ConsentState state) {
    _state = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
