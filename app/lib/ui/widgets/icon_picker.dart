import 'package:flutter/material.dart';

import '../theme_icons.dart';

/// Shows a floating dialog to pick a theme icon from the app's library.
/// Returns the chosen icon id, or null if dismissed.
Future<String?> showThemeIconPicker(
  BuildContext context, {
  String? currentIconId,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _IconPickerDialog(currentIconId: currentIconId),
  );
}

class _IconPickerDialog extends StatelessWidget {
  final String? currentIconId;

  const _IconPickerDialog({this.currentIconId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Escolher ícone do tema'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final option in ThemeIcons.all)
              _IconCell(
                option: option,
                selected: option.id == currentIconId,
                onTap: () => Navigator.pop(context, option.id),
                scheme: scheme,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _IconCell extends StatelessWidget {
  final ThemeIconOption option;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _IconCell({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? scheme.primary.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(option.icon, color: scheme.primary),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
