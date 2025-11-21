import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// 富文本編輯器 Widget
/// 使用 flutter_quill 提供所見即所得的編輯體驗
class RichTextEditor extends StatelessWidget {
  final QuillController controller;
  final String? hintText;
  final int? maxLength;
  final double? height;

  const RichTextEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 工具列
        QuillSimpleToolbar(
          controller: controller,
          config: QuillSimpleToolbarConfig(
            showAlignmentButtons: false,
            showBackgroundColorButton: false,
            showCenterAlignment: false,
            showCodeBlock: false,
            showColorButton: false,
            showDirection: false,
            showFontFamily: false,
            showFontSize: false,
            showIndent: false,
            showInlineCode: false,
            showJustifyAlignment: false,
            showLeftAlignment: false,
            showLink: false,
            showQuote: false,
            showRightAlignment: false,
            showSearchButton: false,
            showSmallButton: false,
            showStrikeThrough: false,
            showSubscript: false,
            showSuperscript: false,
            showUnderLineButton: false,
            showClearFormat: true,
            multiRowsDisplay: false,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
        ),
        // 編輯器
        Container(
          height: height ?? 224.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              padding: const EdgeInsets.all(16),
              placeholder: hintText,
              autoFocus: false,
              expands: false,
              scrollable: true,
            ),
          ),
        ),
        // 字數統計
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, child) {
                  final length = controller.document
                      .toPlainText()
                      .trim()
                      .length;
                  return Text(
                    '$length / $maxLength',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: length > maxLength!
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
