import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';

/// A unified timeline item that can represent either a narration-based
/// journey entry or a quick-guide photo entry.
sealed class JourneyItem {
  String get id;
  DateTime get createdAt;

  /// Text used for keyword search across all item types.
  String get searchableText;
}

/// Wraps a [JourneyEntry] (narration-based) for display in the timeline.
class NarrationJourneyItem extends JourneyItem {
  final JourneyEntry entry;

  NarrationJourneyItem(this.entry);

  @override
  String get id => entry.id;

  @override
  DateTime get createdAt => entry.createdAt;

  @override
  String get searchableText =>
      '${entry.place.name} ${entry.place.address} '
      '${entry.narrationContent.text}';
}

/// Wraps a [QuickGuideEntry] (photo-based) for display in the timeline.
class QuickGuideJourneyItem extends JourneyItem {
  final QuickGuideEntry entry;

  QuickGuideJourneyItem(this.entry);

  @override
  String get id => entry.id;

  @override
  DateTime get createdAt => entry.createdAt;

  @override
  String get searchableText => entry.aiDescription;
}
