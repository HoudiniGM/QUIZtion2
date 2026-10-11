import 'package:flutter/material.dart';

import '../../domain/content_type.dart';

/// Renders a piece of content (statement, option or explanation) honoring the
/// type: plain text or code block.
///
/// For code (requirements, section 10):
/// - uses a monospaced font;
/// - preserves spaces, line breaks and indentation;
/// - does not execute the code and does not interpret it as an instruction.
class ContentView extends StatelessWidget {
  final String text;
  final ContentType type;
  final TextStyle? textStyle;

  const ContentView({
    super.key,
    required this.text,
    this.type = ContentType.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (type == ContentType.code) {
      return _CodeBlock(code: text);
    }
    return Text(text, style: textStyle);
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Courier New', 'monospace'],
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
