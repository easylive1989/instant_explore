import 'dart:async';

import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/domain/repositories/appearance_preferences_repository.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements AppearancePreferencesRepository {
  BrandAccent? accent;
  ReadingSurface? reading;
  HeadlineFont? font;

  @override
  Future<BrandAccent?> loadAccent() async => accent;
  @override
  Future<void> saveAccent(BrandAccent a) async => accent = a;
  @override
  Future<ReadingSurface?> loadReadingSurface() async => reading;
  @override
  Future<void> saveReadingSurface(ReadingSurface s) async => reading = s;
  @override
  Future<HeadlineFont?> loadHeadlineFont() async => font;
  @override
  Future<void> saveHeadlineFont(HeadlineFont f) async => font = f;
}

class _BlockingRepo implements AppearancePreferencesRepository {
  _BlockingRepo(this._accent);
  final Completer<BrandAccent?> _accent;
  @override
  Future<BrandAccent?> loadAccent() => _accent.future;
  @override
  Future<void> saveAccent(BrandAccent a) async {}
  @override
  Future<ReadingSurface?> loadReadingSurface() async => null;
  @override
  Future<void> saveReadingSurface(ReadingSurface s) async {}
  @override
  Future<HeadlineFont?> loadHeadlineFont() async => null;
  @override
  Future<void> saveHeadlineFont(HeadlineFont f) async {}
}

ProviderContainer _container(_FakeRepo repo) {
  final c = ProviderContainer(
    overrides: [
      appearancePreferencesRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('AppearanceNotifier', () {
    test('defaults to terracotta / paper / serif', () {
      final c = _container(_FakeRepo());
      final s = c.read(appearanceNotifierProvider);
      expect(s.accent, BrandAccent.terracotta);
      expect(s.reading, ReadingSurface.paper);
      expect(s.headlineFont, HeadlineFont.serif);
    });

    test('applies persisted values after async load', () async {
      final repo = _FakeRepo()
        ..accent = BrandAccent.sage
        ..reading = ReadingSurface.night
        ..font = HeadlineFont.sans;
      final c = _container(repo);
      c.read(appearanceNotifierProvider); // trigger build
      await Future<void>.delayed(Duration.zero);

      final s = c.read(appearanceNotifierProvider);
      expect(s.accent, BrandAccent.sage);
      expect(s.reading, ReadingSurface.night);
      expect(s.headlineFont, HeadlineFont.sans);
    });

    test('setAccent updates state and persists', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      c.read(appearanceNotifierProvider);

      await c
          .read(appearanceNotifierProvider.notifier)
          .setAccent(BrandAccent.amber);

      expect(c.read(appearanceNotifierProvider).accent, BrandAccent.amber);
      expect(repo.accent, BrandAccent.amber);
    });

    test('setReadingSurface and setHeadlineFont update + persist', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      c.read(appearanceNotifierProvider);

      await c
          .read(appearanceNotifierProvider.notifier)
          .setReadingSurface(ReadingSurface.sepia);
      await c
          .read(appearanceNotifierProvider.notifier)
          .setHeadlineFont(HeadlineFont.sans);

      final s = c.read(appearanceNotifierProvider);
      expect(s.reading, ReadingSurface.sepia);
      expect(s.headlineFont, HeadlineFont.sans);
      expect(repo.reading, ReadingSurface.sepia);
      expect(repo.font, HeadlineFont.sans);
    });
    test('setAccent before load resolves is not overwritten', () async {
      final completer = Completer<BrandAccent?>();
      final repo = _BlockingRepo(completer);
      final c = ProviderContainer(
        overrides: [
          appearancePreferencesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);

      c.read(appearanceNotifierProvider); // triggers build + load (blocks on accent)
      await c
          .read(appearanceNotifierProvider.notifier)
          .setAccent(BrandAccent.amber);
      completer.complete(BrandAccent.sage); // load now resolves with a different value
      await Future<void>.delayed(Duration.zero);

      expect(c.read(appearanceNotifierProvider).accent, BrandAccent.amber);
    });
  });
}
