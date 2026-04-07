import 'package:flutter/material.dart';

/// Forma de recorte da bandeira.
enum SelecaoFlagShape {
  /// Retângulo com cantos arredondados ([borderRadius]).
  roundedRect,

  /// Círculo (avatar); usa o maior lado entre [width] e [height] como diâmetro.
  circle,
}

/// Exibe a bandeira a partir de [bandeiraUrl] (ex.: CDN flagcdn).
///
/// No **Flutter Web**, o carregamento padrão de rede usa `fetch` e sofre com
/// CORS em URLs de terceiros. [WebHtmlElementStrategy.prefer] usa `<img>` no
/// navegador, que exibe imagens cross-origin sem exigir CORS no CDN.
class SelecaoFlagImage extends StatelessWidget {
  const SelecaoFlagImage({
    super.key,
    required this.bandeiraUrl,
    this.width = 40,
    this.height = 28,
    this.borderRadius = 4,
    this.shape = SelecaoFlagShape.roundedRect,
  });

  final String bandeiraUrl;
  final double width;
  final double height;
  final double borderRadius;
  final SelecaoFlagShape shape;

  double get _diameter {
    final d = width > height ? width : height;
    return d > 0 ? d : 40;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCircle = shape == SelecaoFlagShape.circle;
    final w = isCircle ? _diameter : width;
    final h = isCircle ? _diameter : height;

    if (bandeiraUrl.trim().isEmpty) {
      return Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.flag_outlined, size: w * 0.45, color: scheme.outline),
      );
    }

    final image = Image.network(
      bandeiraUrl.trim(),
      width: w,
      height: h,
      fit: BoxFit.cover,
      gaplessPlayback: false,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, __, ___) => Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.flag_outlined, size: w * 0.45, color: scheme.outline),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: w,
          height: h,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
    );

    if (isCircle) {
      return ClipOval(child: image);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
