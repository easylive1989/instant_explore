import 'package:context_app/features/journey/domain/models/journey_entry.dart';

/// A unified timeline item. Currently only narration entries are supported,
/// but the sealed wrapper is kept so additional sources can be reintroduced
/// without churning every call site.
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
