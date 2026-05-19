import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/share/data/share_intent_handler.dart';
import 'package:context_app/features/share/presentation/controllers/share_intent_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Provides the [ShareIntentHandler] instance.
final shareIntentHandlerProvider = Provider<ShareIntentHandler>((ref) {
  final repository = ref.watch(placesRepositoryProvider);
  return ShareIntentHandler(repository);
});

/// Holds the pending shared [Place] (loading / data / error).
///
/// `null` means no share is in flight. Watch this from the app root to
/// react to incoming Google Maps shares.
final shareIntentControllerProvider =
    NotifierProvider<ShareIntentController, AsyncValue<Place>?>(
      ShareIntentController.new,
    );

/// Initialises the OS-level share intent listeners.
///
/// Watch this provider from the app root once to start listening. It
/// handles both cold-start (initial media) and hot (stream) shares.
final shareIntentInitProvider = Provider<void>((ref) {
  final controller = ref.read(shareIntentControllerProvider.notifier);

  // Cold-start: app was launched via a share.
  ReceiveSharingIntent.instance.getInitialMedia().then(
    controller.handleSharedMedia,
  );

  // Hot: shares received while the app is running.
  final subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
    controller.handleSharedMedia,
  );
  ref.onDispose(subscription.cancel);
});
