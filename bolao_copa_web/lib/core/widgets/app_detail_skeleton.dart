import 'package:flutter/material.dart';

/// Skeleton para ecrã de detalhe (um cartão principal + linhas de texto).
///
/// Use enquanto carrega um único recurso (ex.: jogo).
class AppDetailSkeleton extends StatelessWidget {
  const AppDetailSkeleton({super.key, this.padding = const EdgeInsets.all(16)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 200, height: 22, radius: 8, color: base),
                  const SizedBox(height: 16),
                  _Bone(width: double.infinity, height: 14, radius: 6, color: base),
                  const SizedBox(height: 10),
                  _Bone(width: 260, height: 14, radius: 6, color: base),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _Bone(width: double.infinity, height: 48, radius: 12, color: base)),
                      const SizedBox(width: 16),
                      Expanded(child: _Bone(width: double.infinity, height: 48, radius: 12, color: base)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      constraints: width == double.infinity
          ? const BoxConstraints(minWidth: 0, maxWidth: double.infinity)
          : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
