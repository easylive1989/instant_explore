import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/share/data/shared_journey_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger('JourneyShareService');

/// Persists a journey entry to Supabase and triggers the system
/// share sheet with a public link.
class JourneyShareService {
  JourneyShareService({required SharedJourneyRepository repository})
    : _repository = repository;

  final SharedJourneyRepository _repository;

  /// Creates a public share link for a passport [entry] and opens
  /// the platform share sheet. Returns the URL on success.
  Future<String?> shareJourneyLink(JourneyEntry entry) {
    return _shareWith(
      payload: SharedJourneyPayload(
        placeId: entry.place.id,
        placeName: entry.place.name,
        placeAddress: entry.place.address,
        imageUrl: entry.place.imageUrl,
        narrationText: entry.narrationContent.text,
        narrationStyles: entry.narrationAspects.map((a) => a.key).toList(),
        language: entry.language.code,
        visitedAt: entry.createdAt,
      ),
      title: entry.place.name,
    );
  }

  /// Creates a public share link for a quick-guide [entry] and opens
  /// the platform share sheet. The captured image is uploaded so it
  /// can be rendered on the landing page.
  Future<String?> shareQuickGuideLink(
    QuickGuideEntry entry, {
    required String defaultTitle,
  }) {
    return _shareWith(
      payload: SharedJourneyPayload(
        placeId: 'quick-guide:${entry.id}',
        placeName: defaultTitle,
        imageBytes: entry.imageBytes,
        narrationText: entry.aiDescription,
        language: entry.language.code,
        visitedAt: entry.createdAt,
      ),
      title: defaultTitle,
    );
  }

  Future<String?> _shareWith({
    required SharedJourneyPayload payload,
    required String title,
  }) async {
    try {
      final url = await _repository.share(payload);
      final message = '${'share_link.share_text'.tr()}\n\n$title\n$url';
      await Share.share(message, subject: title);
      return url;
    } catch (e, stack) {
      _log.severe('Failed to share journey link', e, stack);
      return null;
    }
  }
}
