/// Result of a Trip → PDF export operation.
///
/// `filePath` points to the generated PDF in temporary storage (already
/// shared via the system share sheet at the call site).
///
/// `missingImagePlaceNames` lists places whose main image failed to download
/// and were substituted with a placeholder. Empty when all images loaded.
class PdfExportResult {
  final String filePath;
  final List<String> missingImagePlaceNames;

  const PdfExportResult({
    required this.filePath,
    this.missingImagePlaceNames = const [],
  });

  bool get hasMissingImages => missingImagePlaceNames.isNotEmpty;
}

/// Raised when the requested Trip has no entries to export.
class EmptyTripExportException implements Exception {
  final String tripId;
  const EmptyTripExportException(this.tripId);

  @override
  String toString() => 'EmptyTripExportException: trip $tripId has no entries';
}
