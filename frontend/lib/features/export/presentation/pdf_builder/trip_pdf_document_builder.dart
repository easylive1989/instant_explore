import 'dart:typed_data';

import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

/// Pre-translated strings used while building the PDF.
class PdfLabels {
  final String pageOfTotal;

  const PdfLabels({required this.pageOfTotal});

  String renderPageOfTotal(int index, int total) => pageOfTotal
      .replaceAll('{index}', '$index')
      .replaceAll('{total}', '$total');
}

/// Builds the binary PDF document for a Trip export.
///
/// The builder is deliberately side-effect free: fonts and pre-rendered
/// cover bytes are injected, so the service layer can handle IO.
class TripPdfDocumentBuilder {
  final pw.Font regularFont;
  final pw.Font boldFont;
  final PdfLabels labels;

  const TripPdfDocumentBuilder({
    required this.regularFont,
    required this.boldFont,
    required this.labels,
  });

  Future<Uint8List> build({
    required Trip trip,
    required List<PdfEntryData> entries,
    required Uint8List coverPngBytes,
  }) async {
    final doc = pw.Document(
      title: trip.name.isEmpty ? 'Trip' : trip.name,
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    doc.addPage(_buildCoverPage(coverPngBytes));

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      doc.addPage(_buildEntryPage(entry, i + 1, entries.length));
    }

    return doc.save();
  }

  pw.Page _buildCoverPage(Uint8List coverPngBytes) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Image(pw.MemoryImage(coverPngBytes), fit: pw.BoxFit.cover),
      ),
    );
  }

  pw.Page _buildEntryPage(PdfEntryData entry, int index, int total) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 56, 48, 48),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          labels.renderPageOfTotal(index, total),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        if (entry.imageBytes != null)
          pw.Container(
            height: 260,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              image: pw.DecorationImage(
                image: pw.MemoryImage(entry.imageBytes!),
                fit: pw.BoxFit.cover,
              ),
            ),
          )
        else
          pw.Container(
            height: 200,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              gradient: const pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFFE6EDF5),
                  PdfColor.fromInt(0xFFD1DCEA),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
          ),
        pw.SizedBox(height: 20),
        pw.Text(
          _formatDate(entry.date),
          style: pw.TextStyle(
            fontSize: 10,
            color: const PdfColor.fromInt(0xFF137FEC),
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          entry.title,
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            height: 1.2,
          ),
        ),
        if (entry.address != null && entry.address!.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            entry.address!,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ],
        if (entry.chipLabels.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entry.chipLabels
                .map(
                  (label) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0x26137FEC),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF137FEC),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Container(height: 1, color: const PdfColor.fromInt(0x1A000000)),
        pw.SizedBox(height: 20),
        pw.Text(
          entry.bodyText,
          style: const pw.TextStyle(
            fontSize: 12,
            lineSpacing: 4,
            letterSpacing: 0.2,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${date.year}.${pad(date.month)}.${pad(date.day)}';
  }
}
