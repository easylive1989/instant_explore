import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/sync/domain/services/remote_sync_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSavedLocationsRemoteDataSource
    implements RemoteSyncDataSource<SavedLocationEntry> {
  SupabaseSavedLocationsRemoteDataSource(this._client);

  static const _table = 'saved_locations';
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError(
        'SupabaseSavedLocationsRemoteDataSource called without auth',
      );
    }
    return id;
  }

  @override
  Future<List<SavedLocationEntry>> fetchAll() async {
    final rows = await _client.from(_table).select().eq('user_id', _userId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(SavedLocationEntry item) async {
    await _client.from(_table).upsert(_toRow(item));
  }

  @override
  Future<void> delete(String placeId) async {
    await _client
        .from(_table)
        .delete()
        .eq('user_id', _userId)
        .eq('place_id', placeId);
  }

  Map<String, dynamic> _toRow(SavedLocationEntry entry) => {
    'place_id': entry.placeId,
    'user_id': _userId,
    'name': entry.name,
    'formatted_address': entry.address,
    'latitude': entry.latitude,
    'longitude': entry.longitude,
    'types': entry.tags,
    'photos': entry.photosJson,
    'category_key': entry.categoryKey,
    'saved_at': entry.savedAt.toIso8601String(),
    'updated_at': entry.updatedAt.toIso8601String(),
  };

  static SavedLocationEntry _fromRow(Map<String, dynamic> row) {
    final savedAt = DateTime.parse(row['saved_at'] as String);
    final updatedAt = row['updated_at'] != null
        ? DateTime.parse(row['updated_at'] as String)
        : savedAt;
    final photos = (row['photos'] as List<dynamic>? ?? const [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();

    return SavedLocationEntry(
      placeId: row['place_id'] as String,
      name: row['name'] as String,
      address: row['formatted_address'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      tags: (row['types'] as List<dynamic>? ?? const []).cast<String>(),
      photosJson: photos,
      categoryKey: row['category_key'] as String,
      savedAt: savedAt,
      updatedAt: updatedAt,
    );
  }
}
