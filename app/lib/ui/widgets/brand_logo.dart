import 'package:flutter/material.dart';

/// Asset paths for the brand logos. Replace the files in assets/images/.
abstract class LogoAssets {
  static const horizontal = 'assets/nome-quiztion.png';
  static const mark = 'assets/logo-quiztion.png';
}

/// Displays the horizontal logo (with text). Falls back to a styled "QUIZtion"
/// text if the asset is missing, so the app works before the file is added.
class BrandLogoHorizontal extends StatelessWidget {
  final double height;
  final Color? fallbackColor;

  const BrandLogoHorizontal({
    super.key,
    this.height = 32,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      LogoAssets.horizontal,
      height: height,
      errorBuilder: (context, _, __) => Text(
        'QUIZtion',
        style: TextStyle(
          fontSize: height * 0.7,
          fontWeight: FontWeight.bold,
          color: fallbackColor ?? Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// An AppBar title that shows the icon-only logo next to a screen title.
/// Used on non-home screens (home uses the full horizontal logo).
class BrandedAppBarTitle extends StatelessWidget {
  final String title;

  const BrandedAppBarTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogoMark(size: 34),
        const SizedBox(width: 10),
        Text(title),
      ],
    );
  }
}

/// Displays the icon-only logo. Falls back to a Material icon if missing.
class BrandLogoMark extends StatelessWidget {
  final double size;

  const BrandLogoMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      LogoAssets.mark,
      height: size,
      width: size,
      errorBuilder: (context, _, __) => Icon(
        Icons.psychology,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
