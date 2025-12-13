import 'package:context_app/features/passport/models/passport_entry.dart';

abstract class PassportRepository {
  Future<List<PassportEntry>> getPassportEntries(String userId);
  Future<void> addPassportEntry(PassportEntry entry);
  Future<void> deletePassportEntry(String id);
}
