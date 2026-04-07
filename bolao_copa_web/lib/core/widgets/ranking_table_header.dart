import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cabeçalho de tabela de ranking (mockup: colunas Pos., Usuário, Pontos, Total apostas).
class RankingTableHeader extends StatelessWidget {
  const RankingTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onInverseSurface,
      letterSpacing: 0.2,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(color: AppTheme.secondaryGold.withValues(alpha: 0.65), width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('Pos.', style: label)),
          Expanded(
            flex: 5,
            child: Text('Usuário', style: label),
          ),
          SizedBox(
            width: 56,
            child: Text('Pontos', style: label, textAlign: TextAlign.end),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'Total\napostas',
              style: label?.copyWith(fontSize: 11, height: 1.15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
