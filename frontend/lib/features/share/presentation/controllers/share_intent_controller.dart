import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/share/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Holds the [Place] resolved from an incoming share intent.
///
/// `null` means no share is pending. UI consumers should watch this
/// state, react to the resolved place (typically by saving it), then
/// call [clear] to reset.
class ShareIntentController extends Notifier<AsyncValue<Place>?> {
  static final _log = Logger('ShareIntentController');

  @override
  AsyncValue<Place>? build() => null;

  /// Resets the pending share. Call after consuming the resolved place
  /// (or after surfacing an error to the user).
  void clear() => state = null;

  /// Extracts the first usable text payload from [files] and resolves
  /// it. No-op when the list is empty or contains no text.
  Future<void> handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    for (final file in files) {
      // The shared text may live in `path` or `message` depending on
      // the platform and package version.
      final text = file.message?.isNotEmpty == true ? file.message! : file.path;
      if (text.isEmpty) continue;

      _log.info('Received shared text: $text');
      await handleSharedText(text);
      return;
    }
  }

  /// Resolves [sharedText] into a [Place] and exposes the outcome on
  /// [state].
  Future<void> handleSharedText(String sharedText) async {
    state = const AsyncValue.loading();
    try {
      final handler = ref.read(shareIntentHandlerProvider);
      final language = ref.read(currentLanguageProvider);
      final place = await handler.resolveSharedText(
        sharedText,
        language: language,
      );

      if (place != null) {
        state = AsyncValue.data(place);
      } else {
        state = AsyncValue.error('shared_place.not_found', StackTrace.current);
      }
    } catch (e, stack) {
      _log.warning('Failed to resolve shared place', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }
}
