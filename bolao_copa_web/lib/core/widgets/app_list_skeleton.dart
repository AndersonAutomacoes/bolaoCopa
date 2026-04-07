import 'package:flutter/material.dart';

import '../theme/app_layout.dart';

/// Placeholder de lista (skeleton) alinhado a cards 16px da direção visual v1.
///
/// Use no `waiting` de [FutureBuilder] para listas de cartões ou [ListTile].
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    super.key,
    this.itemCount = 8,
    this.padding = AppLayout.pagePaddingAll,
  }) : _ranking = false;

  /// Variante para listas de ranking (posição + colunas).
  const AppListSkeleton.ranking({
    super.key,
    this.itemCount = 10,
    this.padding = AppLayout.pagePaddingAll,
  }) : _ranking = true;

  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool _ranking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (_ranking) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _Bone(width: 40, height: 40, radius: 20, color: base),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Bone(width: 140, height: 12, radius: 6, color: base),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Bone(width: 36, height: 22, radius: 6, color: base),
                ],
              ),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(width: 40, height: 40, radius: 20, color: base),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 14,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Bone(width: 180, height: 12, radius: 6, color: base),
                      const SizedBox(height: 8),
                      _Bone(width: 120, height: 12, radius: 6, color: base),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
