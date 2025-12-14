import 'package:context_app/features/journey/domain/journey_repository.dart';
import 'package:context_app/features/journey/models/journey_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseJourneyRepository implements JourneyRepository {
  final SupabaseClient _client;

  SupabaseJourneyRepository(this._client);

  @override
  Future<List<JourneyEntry>> getJourneyEntries(String userId) async {
    final response = await _client
        .from('passport_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => JourneyEntry.fromJson(json)).toList();
  }

  @override
  Future<void> addJourneyEntry(JourneyEntry entry) async {
    await _client.from('passport_entries').insert(entry.toJson());
  }

  @override
  Future<void> deleteJourneyEntry(String id) async {
    await _client.from('passport_entries').delete().eq('id', id);
  }
}

final passportRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(Supabase.instance.client);
});
