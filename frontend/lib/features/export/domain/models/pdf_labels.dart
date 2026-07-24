/// Pre-translated strings used while building the PDF.
class PdfLabels {
  final String pageOfTotal;

  const PdfLabels({required this.pageOfTotal});

  String renderPageOfTotal(int index, int total) => pageOfTotal
      .replaceAll('{index}', '$index')
      .replaceAll('{total}', '$total');
}
