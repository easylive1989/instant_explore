import 'package:context_app/app/config/appearance_options.dart';

/// Persistence for the user's Field Journal appearance choices.
///
/// Returns `null` when a value has never been saved so callers can apply
/// their own default.
abstract interface class AppearancePreferencesRepository {
  /// Returns the saved brand accent, or null if never saved.
  Future<BrandAccent?> loadAccent();

  /// Persists the chosen brand [accent].
  Future<void> saveAccent(BrandAccent accent);

  /// Returns the saved reading surface, or null if never saved.
  Future<ReadingSurface?> loadReadingSurface();

  /// Persists the chosen reading [surface].
  Future<void> saveReadingSurface(ReadingSurface surface);

  /// Returns the saved headline font, or null if never saved.
  Future<HeadlineFont?> loadHeadlineFont();

  /// Persists the chosen headline [font].
  Future<void> saveHeadlineFont(HeadlineFont font);
}
