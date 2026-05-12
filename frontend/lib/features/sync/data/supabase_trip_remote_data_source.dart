import 'package:context_app/features/sync/domain/services/remote_sync_data_source.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTripRemoteDataSource implements RemoteSyncDataSource<Trip> {
  SupabaseTripRemoteDataSource(this._client);

  static const _table = 'trips';
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('SupabaseTripRemoteDataSource called without auth');
    }
    return id;
  }

  @override
  Future<List<Trip>> fetchAll() async {
    final rows = await _client.from(_table).select().eq('user_id', _userId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(Trip item) async {
    await _client.from(_table).upsert(_toRow(item));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('user_id', _userId).eq('id', id);
  }

  Map<String, dynamic> _toRow(Trip trip) => {
    'id': trip.id,
    'user_id': _userId,
    'name': trip.name,
    'start_date': trip.startDate?.toIso8601String(),
    'end_date': trip.endDate?.toIso8601String(),
    'cover_image_url': trip.coverImageUrl,
    'description': trip.description,
    'created_at': trip.createdAt.toIso8601String(),
    'updated_at': trip.updatedAt.toIso8601String(),
  };

  static Trip _fromRow(Map<String, dynamic> row) {
    DateTime? parseTs(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.parse(v) : null;
    final createdAt = DateTime.parse(row['created_at'] as String);
    final updatedAt = row['updated_at'] != null
        ? DateTime.parse(row['updated_at'] as String)
        : createdAt;

    return Trip(
      id: row['id'] as String,
      name: row['name'] as String,
      startDate: parseTs(row['start_date']),
      endDate: parseTs(row['end_date']),
      coverImageUrl: row['cover_image_url'] as String?,
      description: row['description'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
