import 'dart:async';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/share/data/share_intent_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final _log = Logger('ShareProviders');

/// Provides the [ShareIntentHandler] instance.
final shareIntentHandlerProvider = Provider<ShareIntentHandler>((ref) {
  final repository = ref.watch(placesRepositoryProvider);
  return ShareIntentHandler(repository);
});

/// Holds the [Place] resolved from an incoming share intent.
///
/// `null` means no share is pending.
/// Consumers should read this, navigate to the config screen,
/// then clear it.
final pendingSharedPlaceProvider =
    StateProvider<AsyncValue<Place>?>((ref) => null);

/// Provider that initialises share intent listeners.
///
/// Watch this provider from the app root to start listening.
/// It handles both cold-start (initial media) and hot (stream)
/// share intents.
final shareIntentInitProvider = Provider<void>((ref) {
  // Handle the initial shared content (app was closed).
  ReceiveSharingIntent.instance
      .getInitialMedia()
      .then((List<SharedMediaFile> files) {
    _handleSharedMedia(ref, files);
  });

  // Handle shares while the app is running.
  final subscription = ReceiveSharingIntent.instance
      .getMediaStream()
      .listen((files) {
    _handleSharedMedia(ref, files);
  });

  ref.onDispose(subscription.cancel);
});

void _handleSharedMedia(Ref ref, List<SharedMediaFile> files) {
  if (files.isEmpty) return;

  // Look for text content (Google Maps shares text/plain).
  // The shared text may be in `path` or `message` depending on the
  // platform and package version.
  for (final file in files) {
    final text = file.message?.isNotEmpty == true
        ? file.message!
        : file.path;
    if (text.isEmpty) continue;

    _log.info('Received shared text: $text');
    _resolveAndSetPlace(ref, text);
    return;
  }
}

Future<void> _resolveAndSetPlace(Ref ref, String sharedText) async {
  final notifier = ref.read(pendingSharedPlaceProvider.notifier);
  notifier.state = const AsyncValue.loading();

  try {
    final handler = ref.read(shareIntentHandlerProvider);
    final language = ref.read(currentLanguageProvider);
    final place = await handler.resolveSharedText(
      sharedText,
      language: language,
    );

    if (place != null) {
      notifier.state = AsyncValue.data(place);
    } else {
      notifier.state = AsyncValue.error(
        'shared_place.not_found',
        StackTrace.current,
      );
    }
  } catch (e, stack) {
    _log.warning('Failed to resolve shared place', e, stack);
    notifier.state = AsyncValue.error(e, stack);
  }
}
