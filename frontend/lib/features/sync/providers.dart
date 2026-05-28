import 'package:context_app/features/auth/providers.dart';
import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/saved_locations/data/hive_saved_locations_repository.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';
import 'package:context_app/features/sync/data/supabase_journey_remote_data_source.dart';
import 'package:context_app/features/sync/data/supabase_saved_locations_remote_data_source.dart';
import 'package:context_app/features/sync/data/supabase_trip_remote_data_source.dart';
import 'package:context_app/features/sync/data/syncing_journey_repository.dart';
import 'package:context_app/features/sync/data/syncing_saved_locations_repository.dart';
import 'package:context_app/features/sync/data/syncing_trip_repository.dart';
import 'package:context_app/features/sync/domain/services/remote_sync_data_source.dart';
import 'package:context_app/features/sync/domain/services/sync_coordinator.dart';
import 'package:context_app/features/sync/domain/services/sync_engine.dart';
import 'package:context_app/features/sync/domain/services/sync_session.dart';
import 'package:context_app/features/sync/presentation/controllers/sync_settings_notifier.dart';
import 'package:context_app/features/trip/data/hive_trip_repository.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Sync preference (toggle state) and session.
// ---------------------------------------------------------------------------

final syncSettingsProvider = NotifierProvider<SyncSettingsNotifier, bool>(
  SyncSettingsNotifier.new,
);

/// Combined live snapshot: toggle is on AND user is signed in.
final syncSessionProvider = Provider<SyncSession>((ref) {
  final enabled = ref.watch(syncSettingsProvider);
  final user = ref.watch(currentUserProvider);
  return SyncSession(enabled: enabled, userId: user?.id);
});

// ---------------------------------------------------------------------------
// Local Hive repositories (always used for reads).
// ---------------------------------------------------------------------------

final localJourneyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return HiveJourneyRepository();
});

final localTripRepositoryProvider = Provider<TripRepository>((ref) {
  return HiveTripRepository();
});

final localSavedLocationsRepositoryProvider =
    Provider<SavedLocationsRepository>((ref) {
      return HiveSavedLocationsRepository();
    });

// ---------------------------------------------------------------------------
// Remote data sources (Supabase).
// ---------------------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final journeyRemoteDataSourceProvider =
    Provider<RemoteSyncDataSource<JourneyEntry>>((ref) {
      return SupabaseJourneyRemoteDataSource(ref.watch(supabaseClientProvider));
    });

final tripRemoteDataSourceProvider = Provider<RemoteSyncDataSource<Trip>>((
  ref,
) {
  return SupabaseTripRemoteDataSource(ref.watch(supabaseClientProvider));
});

final savedLocationsRemoteDataSourceProvider =
    Provider<RemoteSyncDataSource<SavedLocationEntry>>((ref) {
      return SupabaseSavedLocationsRemoteDataSource(
        ref.watch(supabaseClientProvider),
      );
    });

// ---------------------------------------------------------------------------
// Sync engines.
// ---------------------------------------------------------------------------

final journeySyncEngineProvider = Provider<SyncEngine<JourneyEntry>>((ref) {
  final local = ref.watch(localJourneyRepositoryProvider);
  return SyncEngine<JourneyEntry>(
    descriptor: SyncEntityDescriptor<JourneyEntry>(
      name: 'journey_entry',
      idOf: (e) => e.id,
      updatedAtOf: (e) => e.updatedAt,
    ),
    remote: ref.watch(journeyRemoteDataSourceProvider),
    loadLocal: local.getAll,
    saveLocal: local.save,
  );
});

final tripSyncEngineProvider = Provider<SyncEngine<Trip>>((ref) {
  final local = ref.watch(localTripRepositoryProvider);
  return SyncEngine<Trip>(
    descriptor: SyncEntityDescriptor<Trip>(
      name: 'trip',
      idOf: (t) => t.id,
      updatedAtOf: (t) => t.updatedAt,
    ),
    remote: ref.watch(tripRemoteDataSourceProvider),
    loadLocal: local.getAll,
    saveLocal: local.save,
  );
});

final savedLocationsSyncEngineProvider =
    Provider<SyncEngine<SavedLocationEntry>>((ref) {
      final local = ref.watch(localSavedLocationsRepositoryProvider);
      return SyncEngine<SavedLocationEntry>(
        descriptor: SyncEntityDescriptor<SavedLocationEntry>(
          name: 'saved_location',
          idOf: (s) => s.placeId,
          updatedAtOf: (s) => s.updatedAt,
        ),
        remote: ref.watch(savedLocationsRemoteDataSourceProvider),
        loadLocal: local.getAll,
        saveLocal: local.save,
      );
    });

// ---------------------------------------------------------------------------
// Public repositories — wrapped versions used by feature providers.
// ---------------------------------------------------------------------------

final syncingJourneyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SyncingJourneyRepository(
    local: ref.watch(localJourneyRepositoryProvider),
    engine: ref.watch(journeySyncEngineProvider),
    session: () => ref.read(syncSessionProvider),
  );
});

final syncingTripRepositoryProvider = Provider<TripRepository>((ref) {
  return SyncingTripRepository(
    local: ref.watch(localTripRepositoryProvider),
    engine: ref.watch(tripSyncEngineProvider),
    session: () => ref.read(syncSessionProvider),
  );
});

final syncingSavedLocationsRepositoryProvider =
    Provider<SavedLocationsRepository>((ref) {
      return SyncingSavedLocationsRepository(
        local: ref.watch(localSavedLocationsRepositoryProvider),
        engine: ref.watch(savedLocationsSyncEngineProvider),
        session: () => ref.read(syncSessionProvider),
      );
    });

// ---------------------------------------------------------------------------
// Coordinator (used to trigger initial full sync).
// ---------------------------------------------------------------------------

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(
    journey: ref.watch(journeySyncEngineProvider),
    trip: ref.watch(tripSyncEngineProvider),
    savedLocations: ref.watch(savedLocationsSyncEngineProvider),
  );
});
