import 'package:equatable/equatable.dart';
import 'package:firebase_ai/firebase_ai.dart';

/// A single web source used by the model to ground its response.
class GroundingSource extends Equatable {
  /// The URI of the retrieved web page.
  final String uri;

  /// Human-readable title of the source. Falls back to the domain or
  /// uri when the upstream payload omits it.
  final String title;

  const GroundingSource({required this.uri, required this.title});

  @override
  List<Object?> get props => [uri, title];
}

/// Snapshot of Google Search grounding metadata attached to an AI
/// response.
///
/// Used by the UI to satisfy the "Grounding with Google Search" usage
/// requirements — specifically, to display the Search Suggestions
/// entry point (`renderedContent`) whenever the model grounded its
/// answer with a web search.
class GroundingInfo extends Equatable {
  /// HTML/CSS snippet that **must** be rendered in a `WebView` to
  /// comply with Google's grounding usage terms.
  ///
  /// `null` when the upstream response did not include a search
  /// entry point (e.g. grounding was disabled or no search was run).
  final String? renderedContent;

  /// Search queries the model ran to ground its response.
  final List<String> webSearchQueries;

  /// Web sources cited by the model.
  final List<GroundingSource> sources;

  const GroundingInfo({
    required this.renderedContent,
    required this.webSearchQueries,
    required this.sources,
  });

  /// Whether the model actually performed any grounding for this
  /// response. When false the UI should hide grounding affordances
  /// entirely.
  bool get hasGrounding =>
      renderedContent != null ||
      webSearchQueries.isNotEmpty ||
      sources.isNotEmpty;

  /// Builds a [GroundingInfo] from plain fields. Returns `null` when
  /// every field is empty.
  ///
  /// Exposed as a separate entry point because `firebase_ai` does
  /// not re-export `GroundingMetadata` from its public API, so the
  /// mapping can't take the raw object as a parameter (nor be unit
  /// tested with one). Call sites that have a [Candidate] should go
  /// through [fromCandidate].
  static GroundingInfo? fromRaw({
    String? renderedContent,
    List<String> webSearchQueries = const [],
    List<GroundingSource> sources = const [],
  }) {
    final info = GroundingInfo(
      renderedContent: (renderedContent?.isNotEmpty == true)
          ? renderedContent
          : null,
      webSearchQueries: List.unmodifiable(webSearchQueries),
      sources: List.unmodifiable(sources),
    );
    return info.hasGrounding ? info : null;
  }

  /// Builds a [GroundingInfo] from a [Candidate] returned by
  /// `firebase_ai`. Returns `null` when there is no usable grounding
  /// data.
  static GroundingInfo? fromCandidate(Candidate? candidate) {
    final metadata = candidate?.groundingMetadata;
    if (metadata == null) return null;

    final sources = metadata.groundingChunks
        .map((chunk) => chunk.web)
        .where((web) => web != null && web.uri != null && web.uri!.isNotEmpty)
        .map(
          (web) => GroundingSource(
            uri: web!.uri!,
            title: (web.title?.isNotEmpty == true)
                ? web.title!
                : (web.domain ?? web.uri!),
          ),
        )
        .toList();

    return fromRaw(
      renderedContent: metadata.searchEntryPoint?.renderedContent,
      webSearchQueries: metadata.webSearchQueries,
      sources: sources,
    );
  }

  @override
  List<Object?> get props => [renderedContent, webSearchQueries, sources];
}
