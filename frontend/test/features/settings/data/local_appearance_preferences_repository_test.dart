import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/data/local_appearance_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalAppearancePreferencesRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = LocalAppearancePreferencesRepository();
  });

  group('LocalAppearancePreferencesRepository', () {

    test('returns null fields when nothing saved', () async {
      expect(await repo.loadAccent(), isNull);
      expect(await repo.loadReadingSurface(), isNull);
      expect(await repo.loadHeadlineFont(), isNull);
    });

    test('persists and reloads each field', () async {
      await repo.saveAccent(BrandAccent.sage);
      await repo.saveReadingSurface(ReadingSurface.night);
      await repo.saveHeadlineFont(HeadlineFont.sans);

      expect(await repo.loadAccent(), BrandAccent.sage);
      expect(await repo.loadReadingSurface(), ReadingSurface.night);
      expect(await repo.loadHeadlineFont(), HeadlineFont.sans);
    });
  });
}
