import 'dart:typed_data';

/// Per-entry data prepared for PDF rendering.
///
/// Works for both narration entries (with an optional story hook chip) and
/// quick-guide entries (chips list is empty, address is null).
class PdfEntryData {
  final String title;
  final String? address;
  final DateTime date;
  final String bodyText;
  final List<String> chipLabels;
  final Uint8List? imageBytes;

  const PdfEntryData({
    required this.title,
    required this.date,
    required this.bodyText,
    this.address,
    this.chipLabels = const [],
    this.imageBytes,
  });
}
