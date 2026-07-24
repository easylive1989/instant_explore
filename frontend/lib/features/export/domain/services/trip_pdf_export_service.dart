import 'dart:typed_data';

import 'package:context_app/features/export/domain/models/pdf_entry_data.dart';
import 'package:context_app/features/export/domain/models/pdf_export_result.dart';
import 'package:context_app/features/export/domain/models/pdf_labels.dart';
import 'package:context_app/features/export/domain/services/place_image_downloader.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:pdf/widgets.dart' as pw;

/// Request payload for rendering a Trip cover off-screen.
class CoverRenderRequest {
  final Trip trip;
  final DateTime startDate;
  final DateTime endDate;
  final int entryCount;

  const CoverRenderRequest({
    required this.trip,
    required this.startDate,
    required this.endDate,
    required this.entryCount,
  });
}

/// Loaded pair of PDF-compatible fonts — regular weight plus bold.
class PdfFontPair {
  final pw.Font regular;
  final pw.Font bold;
  const PdfFontPair({required this.regular, required this.bold});
}

/// Labels required to produce a PDF (i18n strings pre-resolved at the call
/// site so the service is platform-agnostic).
class TripPdfExportStrings {
  final String stampLabel;
  final String appName;
  final String tagline;
  final String entryCountLabel;
  final PdfLabels pdfLabels;

  const TripPdfExportStrings({
    required this.stampLabel,
    required this.appName,
    required this.tagline,
    required this.entryCountLabel,
    required this.pdfLabels,
  });
}

typedef CoverRendererFn = Future<Uint8List> Function(CoverRenderRequest);
typedef FontLoaderFn = Future<PdfFontPair> Function();
typedef TempFileWriterFn =
    Future<String> Function(Uint8List bytes, String fileName);
typedef PdfShareFn = Future<void> Function(String filePath);
typedef TripItemsFetcher = Future<List<JourneyItem>> Function(String tripId);

/// Renders the final PDF bytes. Injected so the domain service stays free of
/// the presentation-layer `pdf`-package document builder.
typedef PdfDocumentBuilderFn =
    Future<Uint8List> Function({
      required Trip trip,
      required List<PdfEntryData> entries,
      required Uint8List coverPngBytes,
      required PdfFontPair fonts,
      required PdfLabels labels,
    });

/// Orchestrates the Trip → PDF export pipeline.
class TripPdfExportService {
  final TripRepository tripRepository;
  final TripItemsFetcher fetchItems;
  final PlaceImageDownloader imageDownloader;
  final CoverRendererFn renderCover;
  final FontLoaderFn loadFonts;
  final PdfDocumentBuilderFn buildDocument;
  final TempFileWriterFn writeToTemp;
  final PdfShareFn share;

  const TripPdfExportService({
    required this.tripRepository,
    required this.fetchItems,
    required this.imageDownloader,
    required this.renderCover,
    required this.loadFonts,
    required this.buildDocument,
    required this.writeToTemp,
    required this.share,
  });

  /// Exports the given Trip to PDF and opens the system share sheet.
  ///
  /// Throws [EmptyTripExportException] if the Trip has no entries.
  /// Throws [ArgumentError] if the Trip id cannot be resolved.
  Future<PdfExportResult> export({
    required String tripId,
    required TripPdfExportStrings strings,
  }) async {
    final trip = await tripRepository.getById(tripId);
    if (trip == null) {
      throw ArgumentError.value(tripId, 'tripId', 'Trip not found');
    }

    final items = await fetchItems(tripId);
    if (items.isEmpty) {
      throw EmptyTripExportException(tripId);
    }

    final missingImagePlaceNames = <String>[];
    final entries = <PdfEntryData>[];

    for (final item in items) {
      final prepared = await _prepareEntry(item);
      entries.add(prepared.data);
      if (prepared.imageMissing) {
        missingImagePlaceNames.add(prepared.data.title);
      }
    }

    final dates = items.map((i) => i.createdAt).toList()..sort();
    final coverBytes = await renderCover(
      CoverRenderRequest(
        trip: trip,
        startDate: trip.startDate ?? dates.first,
        endDate: trip.endDate ?? dates.last,
        entryCount: items.length,
      ),
    );

    final fonts = await loadFonts();
    final pdfBytes = await buildDocument(
      trip: trip,
      entries: entries,
      coverPngBytes: coverBytes,
      fonts: fonts,
      labels: strings.pdfLabels,
    );

    final filePath = await writeToTemp(pdfBytes, _fileName(trip));
    await share(filePath);

    return PdfExportResult(
      filePath: filePath,
      missingImagePlaceNames: missingImagePlaceNames,
    );
  }

  Future<_PreparedEntry> _prepareEntry(JourneyItem item) async {
    return switch (item) {
      NarrationJourneyItem(:final entry) => _prepareNarration(entry),
    };
  }

  Future<_PreparedEntry> _prepareNarration(dynamic narrationEntry) async {
    final place = narrationEntry.place;
    final download = await imageDownloader.download(place.imageUrl as String?);
    final hookTitle = narrationEntry.storyHook?.title as String?;
    final chips = hookTitle == null ? const <String>[] : [hookTitle];

    return _PreparedEntry(
      data: PdfEntryData(
        title: place.name as String,
        address: place.address as String?,
        date: narrationEntry.createdAt as DateTime,
        bodyText: narrationEntry.narrationContent.text as String,
        chipLabels: chips,
        imageBytes: download.usedPlaceholder ? null : download.bytes,
      ),
      imageMissing: download.usedPlaceholder,
    );
  }

  String _fileName(Trip trip) {
    final safe = trip.name.trim().isEmpty
        ? _fallbackName(trip.createdAt)
        : trip.name.trim();
    final sanitized = safe.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$sanitized.pdf';
  }

  String _fallbackName(DateTime createdAt) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return 'journey_${createdAt.year}-${pad(createdAt.month)}-${pad(createdAt.day)}';
  }
}

class _PreparedEntry {
  final PdfEntryData data;
  final bool imageMissing;
  const _PreparedEntry({required this.data, required this.imageMissing});
}
