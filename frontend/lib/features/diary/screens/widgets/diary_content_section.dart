import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';

class DiaryContentSection extends StatelessWidget {
  final String? content;

  const DiaryContentSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: ThemeConfig.neutralLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildQuillContent(context, content!),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// 建立 Quill 內容顯示
  Widget _buildQuillContent(BuildContext context, String content) {
    try {
      final deltaJson = jsonDecode(content);
      final document = Document.fromJson(deltaJson);
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return QuillEditor.basic(
        controller: controller,
        config: const QuillEditorConfig(padding: EdgeInsets.zero),
      );
    } catch (e) {
      // 如果無法解析，顯示為純文字（向後相容）
      return Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.8,
          color: ThemeConfig.neutralText,
        ),
      );
    }
  }
}
