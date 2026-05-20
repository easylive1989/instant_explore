import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:context_app/core/services/install_id_provider.dart';

final Logger _log = Logger('FirebaseInstallIdProvider');

/// SharedPreferences key used to store the locally generated UUID
/// fallback when Firebase Analytics declines to provide an
/// `appInstanceId` (e.g. when the user has analytics disabled at the
/// device level).
const String kInstallIdFallbackKey = 'core.install_id.fallback';

/// Signature of a function that returns the Firebase Analytics
/// `appInstanceId`.
///
/// Production code injects `() => FirebaseAnalytics.instance
/// .appInstanceId`; tests inject any async function that yields a
/// deterministic value (or `null` to exercise the fallback path).
typedef AppInstanceIdFetcher = Future<String?> Function();

/// [InstallIdProvider] backed by Firebase Analytics.
///
/// Primary id comes from `FirebaseAnalytics.appInstanceId`. If the SDK
/// returns `null` (analytics disabled at OS level, or transport error),
/// a locally persisted UUID v4 is generated/read from SharedPreferences
/// so that downstream feature-flag hashing remains stable.
///
/// Multiple calls to [get] only hit the underlying fetcher once; the
/// result is memoised in-memory for the lifetime of this instance.
class FirebaseInstallIdProvider implements InstallIdProvider {
  FirebaseInstallIdProvider({
    required AppInstanceIdFetcher fetchAppInstanceId,
    required SharedPreferences prefs,
    Uuid uuid = const Uuid(),
  }) : _fetch = fetchAppInstanceId,
       _prefs = prefs,
       _uuid = uuid;

  final AppInstanceIdFetcher _fetch;
  final SharedPreferences _prefs;
  final Uuid _uuid;

  String? _cached;

  @override
  Future<String> get() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }

    final firebaseId = await _fetch();
    if (firebaseId != null && firebaseId.isNotEmpty) {
      _cached = firebaseId;
      return firebaseId;
    }

    _log.warning(
      'FirebaseAnalytics.appInstanceId unavailable; falling back to '
      'locally persisted UUID.',
    );

    final existing = _prefs.getString(kInstallIdFallbackKey);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }

    final generated = _uuid.v4();
    await _prefs.setString(kInstallIdFallbackKey, generated);
    _cached = generated;
    return generated;
  }
}
