import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:context_app/features/export/domain/services/trip_pdf_export_service.dart';
import 'package:context_app/features/export/presentation/widgets/pdf_cover_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders [PdfCoverWidget] off-screen and returns its PNG bytes.
///
/// Must be called from a mounted widget context — uses [Overlay.of] to host
/// the widget and [RepaintBoundary.toImage] to rasterise it. The context is
/// captured synchronously by the caller before any awaits.
Future<Uint8List> renderPdfCoverOffscreen(
  BuildContext context,
  CoverRenderRequest request, {
  required String stampLabel,
  required String appName,
  required String tagline,
  required String entryCountLabel,
}) async {
  final key = GlobalKey();

  final widget = RepaintBoundary(
    key: key,
    child: MediaQuery(
      data: MediaQuery.of(context),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Localizations.override(
          context: context,
          child: Material(
            color: Colors.transparent,
            child: PdfCoverWidget(
              tripName: request.trip.name,
              startDate: request.startDate,
              endDate: request.endDate,
              entryCount: request.entryCount,
              appName: appName,
              tagline: tagline,
              stampLabel: stampLabel,
              entryCountLabel: entryCountLabel,
            ),
          ),
        ),
      ),
    ),
  );

  final overlayEntry = OverlayEntry(
    builder: (_) => Positioned(left: -10000, top: -10000, child: widget),
  );

  final overlay = Overlay.of(context);
  overlay.insert(overlayEntry);

  // Allow layout + any image decode / text rendering to settle.
  await Future<void>.delayed(const Duration(milliseconds: 300));

  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Cover render boundary disappeared before capture');
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Cover PNG byte data was null');
    }
    return byteData.buffer.asUint8List();
  } finally {
    overlayEntry.remove();
  }
}
