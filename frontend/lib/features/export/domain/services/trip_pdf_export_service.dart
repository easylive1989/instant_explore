import 'dart:typed_data';

import 'package:context_app/features/export/domain/models/pdf_export_result.dart';
import 'package:context_app/features/export/domain/services/place_image_downloader.dart';
import 'package:context_app/features/export/presentation/pdf_builder/trip_pdf_document_builder.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
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
  final Map<NarrationAspect, String> aspectLabels;

  const TripPdfExportStrings({
    required this.stampLabel,
    required this.appName,
    required this.tagline,
    required this.entryCountLabel,
    required this.pdfLabels,
    required this.aspectLabels,
  });
}

typedef CoverRendererFn = Future<Uint8List> Function(CoverRenderRequest);
typedef FontLoaderFn = Future<PdfFontPair> Function();
typedef TempFileWriterFn =
    Future<String> Function(Uint8List bytes, String fileName);
typedef PdfShareFn = Future<void> Function(String filePath);
typedef TripItemsFetcher = Future<List<JourneyItem>> Function(String tripId);

/// Orchestrates the Trip → PDF export pipeline.
class TripPdfExportService {
  final TripRepository tripRepository;
  final TripItemsFetcher fetchItems;
  final PlaceImageDownloader imageDownloader;
  final CoverRendererFn renderCover;
  final FontLoaderFn loadFonts;
  final TempFileWriterFn writeToTemp;
  final PdfShareFn share;

  const TripPdfExportService({
    required this.tripRepository,
    required this.fetchItems,
    required this.imageDownloader,
    required this.renderCover,
    required this.loadFonts,
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
      final prepared = await _prepareEntry(item, strings.aspectLabels);
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
    final builder = TripPdfDocumentBuilder(
      regularFont: fonts.regular,
      boldFont: fonts.bold,
      labels: strings.pdfLabels,
    );

    final pdfBytes = await builder.build(
      trip: trip,
      entries: entries,
      coverPngBytes: coverBytes,
    );

    final filePath = await writeToTemp(pdfBytes, _fileName(trip));
    await share(filePath);

    return PdfExportResult(
      filePath: filePath,
      missingImagePlaceNames: missingImagePlaceNames,
    );
  }

  Future<_PreparedEntry> _prepareEntry(
    JourneyItem item,
    Map<NarrationAspect, String> aspectLabels,
  ) async {
    return switch (item) {
      NarrationJourneyItem(:final entry) => _prepareNarration(
        entry,
        aspectLabels,
      ),
      QuickGuideJourneyItem(:final entry) => _PreparedEntry(
        data: PdfEntryData(
          title: _truncate(entry.aiDescription.split('\n').first, 40),
          date: entry.createdAt,
          bodyText: entry.aiDescription,
          imageBytes: entry.imageBytes,
        ),
        imageMissing: false,
      ),
    };
  }

  Future<_PreparedEntry> _prepareNarration(
    dynamic narrationEntry,
    Map<NarrationAspect, String> aspectLabels,
  ) async {
    final place = narrationEntry.place;
    final download = await imageDownloader.download(place.imageUrl as String?);
    final aspects = (narrationEntry.narrationAspects as Set<NarrationAspect>)
        .map((a) => aspectLabels[a] ?? a.key)
        .toList();

    return _PreparedEntry(
      data: PdfEntryData(
        title: place.name as String,
        address: place.address as String?,
        date: narrationEntry.createdAt as DateTime,
        bodyText: narrationEntry.narrationContent.text as String,
        aspectLabels: aspects,
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

  String _truncate(String input, int max) =>
      input.length <= max ? input : '${input.substring(0, max)}…';
}

class _PreparedEntry {
  final PdfEntryData data;
  final bool imageMissing;
  const _PreparedEntry({required this.data, required this.imageMissing});
}
