import 'package:context_app/app/config/appearance_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appearance option enums', () {
    test('BrandAccent round-trips through storage strings', () {
      for (final v in BrandAccent.values) {
        expect(BrandAccentX.fromStorage(v.storageKey), v);
      }
    });

    test('unknown BrandAccent storage string falls back to terracotta', () {
      expect(BrandAccentX.fromStorage('bogus'), BrandAccent.terracotta);
      expect(BrandAccentX.fromStorage(null), BrandAccent.terracotta);
    });

    test('ReadingSurface round-trips and defaults to paper', () {
      for (final v in ReadingSurface.values) {
        expect(ReadingSurfaceX.fromStorage(v.storageKey), v);
      }
      expect(ReadingSurfaceX.fromStorage('x'), ReadingSurface.paper);
    });

    test('HeadlineFont round-trips and defaults to serif', () {
      for (final v in HeadlineFont.values) {
        expect(HeadlineFontX.fromStorage(v.storageKey), v);
      }
      expect(HeadlineFontX.fromStorage(null), HeadlineFont.serif);
    });
  });
}
