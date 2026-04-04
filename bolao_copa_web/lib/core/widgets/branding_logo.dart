import 'package:flutter/material.dart';

/// Caminho declarado em [pubspec.yaml] (`flutter.assets`).
abstract final class BrandingAssets {
  static const String logoPng = 'assets/branding/logo.png';
}

/// Marca Bolão Copa (asset em [pubspec.yaml] `assets/branding/logo.png`).
/// Em CI ou se o ficheiro faltar, mostra ícone de fallback.
class BrandingLogo extends StatelessWidget {
  const BrandingLogo({
    super.key,
    this.height = 56,
    this.semanticLabel = 'Bolão Copa 2026',
  });

  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(height * 0.18);
    return SizedBox(
      width: height,
      height: height,
      child: Image.asset(
        BrandingAssets.logoPng,
        height: height,
        width: height,
        semanticLabel: semanticLabel,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: height,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: r,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.sports_soccer,
            size: height * 0.55,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
