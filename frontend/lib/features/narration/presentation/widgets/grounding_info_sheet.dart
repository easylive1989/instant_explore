import 'package:context_app/features/narration/domain/models/grounding_info.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens the Google Search grounding info as a modal bottom sheet.
///
/// Shows the required "Search Suggestions" rendered content (per
/// Google's grounding usage terms) and any web sources the model
/// cited.
Future<void> showGroundingInfoSheet(
  BuildContext context, {
  required GroundingInfo grounding,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => GroundingInfoSheet(grounding: grounding),
  );
}

class GroundingInfoSheet extends StatelessWidget {
  final GroundingInfo grounding;

  const GroundingInfoSheet({super.key, required this.grounding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Google 搜尋結果', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (grounding.renderedContent != null)
                    _SearchEntryPointView(
                      renderedContent: grounding.renderedContent!,
                    ),
                  if (grounding.sources.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('來源', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...grounding.sources.map(
                      (source) => _SourceTile(source: source),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEntryPointView extends StatefulWidget {
  final String renderedContent;

  const _SearchEntryPointView({required this.renderedContent});

  @override
  State<_SearchEntryPointView> createState() => _SearchEntryPointViewState();
}

class _SearchEntryPointViewState extends State<_SearchEntryPointView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(widget.renderedContent);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 96, child: WebViewWidget(controller: _controller));
  }
}

class _SourceTile extends StatelessWidget {
  final GroundingSource source;

  const _SourceTile({required this.source});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(source.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(source.uri, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () async {
        final uri = Uri.tryParse(source.uri);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}
