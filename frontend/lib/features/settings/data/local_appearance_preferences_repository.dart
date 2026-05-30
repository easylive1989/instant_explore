import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/domain/repositories/appearance_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AppearancePreferencesRepository] backed by [SharedPreferences].
class LocalAppearancePreferencesRepository
    implements AppearancePreferencesRepository {
  static const _kAccent = 'appearance_accent';
  static const _kReading = 'appearance_reading';
  static const _kHeadlineFont = 'appearance_headline_font';

  @override
  Future<BrandAccent?> loadAccent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccent);
    return raw == null ? null : BrandAccentX.fromStorage(raw);
  }

  @override
  Future<void> saveAccent(BrandAccent accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccent, accent.storageKey);
  }

  @override
  Future<ReadingSurface?> loadReadingSurface() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReading);
    return raw == null ? null : ReadingSurfaceX.fromStorage(raw);
  }

  @override
  Future<void> saveReadingSurface(ReadingSurface surface) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReading, surface.storageKey);
  }

  @override
  Future<HeadlineFont?> loadHeadlineFont() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHeadlineFont);
    return raw == null ? null : HeadlineFontX.fromStorage(raw);
  }

  @override
  Future<void> saveHeadlineFont(HeadlineFont font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHeadlineFont, font.storageKey);
  }
}
