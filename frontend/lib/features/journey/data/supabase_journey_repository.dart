import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/journey/domain/errors/journey_error.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseJourneyRepository implements JourneyRepository {
  final SupabaseClient _client;

  SupabaseJourneyRepository(this._client);

  @override
  Future<List<JourneyEntry>> getJourneyEntries(String userId) async {
    try {
      final response = await _client
          .from('passport_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => JourneyEntry.fromJson(json)).toList();
    } on PostgrestException catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.loadFailed,
        message: '載入旅程記錄失敗',
        originalException: e,
        stackTrace: stackTrace,
        context: {'user_id': userId},
      );
    } catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.unknown,
        message: '發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> addJourneyEntry(JourneyEntry entry) async {
    try {
      await _client.from('passport_entries').insert(entry.toJson());
    } on PostgrestException catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.saveFailed,
        message: '儲存旅程記錄失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.unknown,
        message: '發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteJourneyEntry(String id) async {
    try {
      await _client.from('passport_entries').delete().eq('id', id);
    } on PostgrestException catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.deleteFailed,
        message: '刪除旅程記錄失敗',
        originalException: e,
        stackTrace: stackTrace,
        context: {'entry_id': id},
      );
    } catch (e, stackTrace) {
      throw AppError(
        type: JourneyError.unknown,
        message: '發生未預期的錯誤',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
}
