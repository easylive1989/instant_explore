import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:context_app/core/services/firebase_install_id_provider.dart';
import 'package:context_app/core/services/install_id_provider.dart';
import 'package:context_app/features/analytics/data/firebase_analytics_service.dart';
import 'package:context_app/features/analytics/data/shared_prefs_consent_repository.dart';
import 'package:context_app/features/analytics/domain/services/analytics_service.dart';
import 'package:context_app/features/analytics/domain/services/consent_repository.dart';
import 'package:context_app/features/analytics/presentation/narration_analytics_observer.dart';

/// Async-resolved [SharedPreferences] singleton, used by consent
/// persistence and the lifetime first-narration flag.
///
/// Override in tests (or in `main.dart` for eager init) with
/// `sharedPreferencesProvider.overrideWith(...)`.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Exposes the global [FirebaseAnalytics] singleton so it can be
/// overridden with a fake in widget / integration tests.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);

/// Entry point for any feature that needs to record an analytics event.
///
/// Default implementation forwards to Firebase Analytics; override in
/// tests by replacing [firebaseAnalyticsProvider] or this provider
/// directly with a fake.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(ref.read(firebaseAnalyticsProvider)),
);

/// Navigator observers wired into GoRouter.
///
/// Without a [FirebaseAnalyticsObserver] the app's automatic `screen_view`
/// events reach GA4 with `unifiedScreenName` = `(not set)`, so no in-app
/// funnel can be read. Exposed as a provider so tests (and any surface that
/// must not touch Firebase) can override it with an empty list.
final routeObserversProvider = Provider<List<NavigatorObserver>>((ref) {
  return <NavigatorObserver>[
    FirebaseAnalyticsObserver(analytics: ref.read(firebaseAnalyticsProvider)),
  ];
});

/// Persists and broadcasts the user's analytics consent flag.
///
/// Throws if [sharedPreferencesProvider] has not yet resolved; callers
/// should `await ref.read(sharedPreferencesProvider.future)` once
/// during bootstrap before resolving this provider, or override
/// [sharedPreferencesProvider] with an eagerly-initialised value.
final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  final prefs = ref.read(sharedPreferencesProvider).requireValue;
  final repo = SharedPrefsConsentRepository(prefs);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Returns the stable install id for analytics attribution and
/// (Story 2) feature-flag A/B bucketing.
final installIdProvider = Provider<InstallIdProvider>((ref) {
  final prefs = ref.read(sharedPreferencesProvider).requireValue;
  final analytics = ref.read(firebaseAnalyticsProvider);
  return FirebaseInstallIdProvider(
    fetchAppInstanceId: () => analytics.appInstanceId,
    prefs: prefs,
  );
});

/// Cross-cutting observer that listens to the narration player state
/// and emits analytics events.
///
/// Watch this provider once during app bootstrap (e.g. in `main.dart`
/// or the root widget) so the observer stays alive for the entire
/// session.
final narrationAnalyticsObserverProvider =
    NotifierProvider<NarrationAnalyticsObserver, void>(
      NarrationAnalyticsObserver.new,
    );
