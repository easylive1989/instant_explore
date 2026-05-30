import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of the user's appearance choices.
@immutable
class AppearanceState {
  const AppearanceState({
    this.accent = BrandAccent.terracotta,
    this.reading = ReadingSurface.paper,
    this.headlineFont = HeadlineFont.serif,
  });

  final BrandAccent accent;
  final ReadingSurface reading;
  final HeadlineFont headlineFont;

  /// Returns a copy with the given fields replaced.
  AppearanceState copyWith({
    BrandAccent? accent,
    ReadingSurface? reading,
    HeadlineFont? headlineFont,
  }) {
    return AppearanceState(
      accent: accent ?? this.accent,
      reading: reading ?? this.reading,
      headlineFont: headlineFont ?? this.headlineFont,
    );
  }
}

/// Holds and persists the Field Journal appearance choices.
///
/// `build()` returns defaults synchronously and kicks off an async load so
/// the first frame renders immediately; persisted values are applied as
/// soon as they resolve.
///
/// If a setter is called before the initial load completes, the load is
/// cancelled via [_loaded] so the user's explicit choice is never
/// overwritten by stale persisted data.
class AppearanceNotifier extends Notifier<AppearanceState> {
  /// True once either the async load or a setter has committed state.
  bool _loaded = false;

  @override
  AppearanceState build() {
    _loadFromPrefs();
    return const AppearanceState();
  }

  Future<void> _loadFromPrefs() async {
    final repo = ref.read(appearancePreferencesRepositoryProvider);
    final accent = await repo.loadAccent();
    final reading = await repo.loadReadingSurface();
    final font = await repo.loadHeadlineFont();
    if (_loaded) return; // a setter already ran; persisted values are stale
    _loaded = true;
    state = state.copyWith(
      accent: accent,
      reading: reading,
      headlineFont: font,
    );
  }

  /// Updates the accent and persists the new value.
  Future<void> setAccent(BrandAccent accent) async {
    _loaded = true;
    state = state.copyWith(accent: accent);
    await ref.read(appearancePreferencesRepositoryProvider).saveAccent(accent);
  }

  /// Updates the reading surface and persists the new value.
  Future<void> setReadingSurface(ReadingSurface surface) async {
    _loaded = true;
    state = state.copyWith(reading: surface);
    await ref
        .read(appearancePreferencesRepositoryProvider)
        .saveReadingSurface(surface);
  }

  /// Updates the headline font and persists the new value.
  Future<void> setHeadlineFont(HeadlineFont font) async {
    _loaded = true;
    state = state.copyWith(headlineFont: font);
    await ref
        .read(appearancePreferencesRepositoryProvider)
        .saveHeadlineFont(font);
  }
}
