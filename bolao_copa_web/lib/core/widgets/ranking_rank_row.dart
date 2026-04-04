import 'package:flutter/material.dart';

import '../models/ranking_item_dto.dart';

/// Linha de ranking com hierarquia tipo placar: posição, nome e pontos em destaque.
///
/// Posições 1–3 usam [ColorScheme.secondary] (ouro) com peso visual maior.
class RankingRankRow extends StatelessWidget {
  const RankingRankRow({super.key, required this.item});

  final RankingItemDto item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pos = item.posicao;
    final isTop = pos >= 1 && pos <= 3;
    final name = item.nome?.isNotEmpty == true ? item.nome! : item.email;

    final Color avatarBg;
    final Color avatarFg;
    if (isTop) {
      avatarBg = scheme.secondaryContainer;
      avatarFg = scheme.onSecondaryContainer;
    } else {
      avatarBg = scheme.surfaceContainerHighest;
      avatarFg = scheme.onSurfaceVariant;
    }

    final podiumRing = isTop
        ? Border.all(
            color: scheme.secondary.withValues(alpha: 0.72),
            width: 2,
          )
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: isTop ? 48 : 40,
              height: isTop ? 48 : 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBg,
                  border: podiumRing,
                ),
                child: Center(
                  child: Text(
                    '$pos',
                    style: (isTop ? textTheme.titleLarge : textTheme.titleMedium)?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: avatarFg,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: isTop ? FontWeight.w700 : FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.totalAcertosExatos} placares exatos',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.totalPontos}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isTop ? scheme.secondary : scheme.onSurface,
                  ),
                ),
                Text(
                  'pts',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
