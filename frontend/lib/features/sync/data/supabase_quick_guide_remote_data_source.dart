import 'dart:convert';

import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/sync/domain/services/remote_sync_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseQuickGuideRemoteDataSource
    implements RemoteSyncDataSource<QuickGuideEntry> {
  SupabaseQuickGuideRemoteDataSource(this._client);

  static const _table = 'quick_guide_entries';
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError(
        'SupabaseQuickGuideRemoteDataSource called without auth',
      );
    }
    return id;
  }

  @override
  Future<List<QuickGuideEntry>> fetchAll() async {
    final rows = await _client.from(_table).select().eq('user_id', _userId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(QuickGuideEntry item) async {
    await _client.from(_table).upsert(_toRow(item));
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('user_id', _userId).eq('id', id);
  }

  Map<String, dynamic> _toRow(QuickGuideEntry entry) => {
    'id': entry.id,
    'user_id': _userId,
    'image_base64': base64Encode(entry.imageBytes),
    'ai_description': entry.aiDescription,
    'language': entry.language.code,
    'trip_id': entry.tripId,
    'created_at': entry.createdAt.toIso8601String(),
    'updated_at': entry.updatedAt.toIso8601String(),
  };

  static QuickGuideEntry _fromRow(Map<String, dynamic> row) {
    final createdAt = DateTime.parse(row['created_at'] as String);
    final updatedAt = row['updated_at'] != null
        ? DateTime.parse(row['updated_at'] as String)
        : createdAt;

    return QuickGuideEntry(
      id: row['id'] as String,
      imageBytes: base64Decode(row['image_base64'] as String),
      aiDescription: row['ai_description'] as String,
      createdAt: createdAt,
      updatedAt: updatedAt,
      language: Language(row['language'] as String? ?? 'zh-TW'),
      tripId: row['trip_id'] as String?,
    );
  }
}
