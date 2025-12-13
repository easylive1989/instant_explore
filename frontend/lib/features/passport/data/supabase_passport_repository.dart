import 'package:context_app/features/passport/domain/passport_repository.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePassportRepository implements PassportRepository {
  final SupabaseClient _client;

  SupabasePassportRepository(this._client);

  @override
  Future<List<PassportEntry>> getPassportEntries(String userId) async {
    final response = await _client
        .from('passport_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => PassportEntry.fromJson(json)).toList();
  }

  @override
  Future<void> addPassportEntry(PassportEntry entry) async {
    await _client.from('passport_entries').insert(entry.toJson());
  }

  @override
  Future<void> deletePassportEntry(String id) async {
    await _client.from('passport_entries').delete().eq('id', id);
  }
}

final passportRepositoryProvider = Provider<PassportRepository>((ref) {
  return SupabasePassportRepository(Supabase.instance.client);
});
