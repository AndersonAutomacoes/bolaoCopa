import 'package:flutter/material.dart';

/// Cabeçalho estilo tabela para listas de ranking (posição, participante, pontos).
class RankingTableHeader extends StatelessWidget {
  const RankingTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text('#', style: label),
            ),
            Expanded(
              child: Text('Participante', style: label),
            ),
            SizedBox(
              width: 56,
              child: Text(
                'Pts',
                style: label,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
