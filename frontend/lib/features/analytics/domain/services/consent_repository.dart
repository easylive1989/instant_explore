import 'package:context_app/features/analytics/domain/models/consent_state.dart';

/// Persists the user's analytics consent flag and exposes a stream so
/// the analytics service can react to toggles in real time.
abstract class ConsentRepository {
  /// Returns the currently persisted consent state. If none has ever
  /// been written, implementations MUST seed and return
  /// [ConsentState.defaultOn] (per the "consent default ON" product
  /// decision).
  Future<ConsentState> read();

  /// Persist the given [state]. Subsequent [watch] subscribers receive
  /// the update.
  Future<void> write(ConsentState state);

  /// Emits the current state on subscribe and again on every write.
  Stream<ConsentState> watch();
}
