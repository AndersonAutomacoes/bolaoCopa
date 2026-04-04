import 'package:flutter/material.dart';

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
  });

  final String bandeiraUrl;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (bandeiraUrl.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(Icons.flag_outlined, size: width * 0.45, color: scheme.outline),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        bandeiraUrl.trim(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.flag_outlined, size: width * 0.45, color: scheme.outline),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
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
      ),
    );
  }
}
