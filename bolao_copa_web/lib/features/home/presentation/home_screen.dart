import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppRouter.auth,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final auth = AppRouter.auth;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Início'),
            actions: [
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.meusPalpites),
                icon: const Icon(Icons.edit_note, size: 20),
                label: const Text('Meus palpites'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ColoredBox(
            color: AppTheme.surfacePage,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const SizedBox(height: 8),
                _HeroBlock(scheme: scheme),
                const SizedBox(height: 24),
                _FlowCard(
                  icon: Icons.sports_soccer,
                  title: 'Jogos',
                  subtitle: 'Veja a tabela de jogos e registre seu palpite antes do apito inicial.',
                  onTap: () => context.go(AppRoutes.jogos),
                ),
                const SizedBox(height: 12),
                _FlowCard(
                  icon: Icons.leaderboard,
                  title: 'Ranking',
                  subtitle: 'Desempate: pontos, acertos exatos, data do primeiro palpite.',
                  onTap: () => context.go(AppRoutes.ranking),
                ),
                const SizedBox(height: 12),
                _FlowCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Regras do bolão',
                  subtitle: 'Pontuação, prazos e o que cada plano libera.',
                  onTap: () => context.push(AppRoutes.regras),
                ),
                if (auth.tierPrataOrAbove) ...[
                  const SizedBox(height: 12),
                  _FlowCard(
                    icon: Icons.groups_outlined,
                    title: 'Bolões privados',
                    subtitle: 'Crie um bolão ou entre com o código de convite (Plano Prata ou superior).',
                    onTap: () => context.push(AppRoutes.boloes),
                  ),
                ],
                if (auth.tierOuro) ...[
                  const SizedBox(height: 12),
                  _FlowCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Premiação',
                    subtitle: 'Regras e acompanhamento de premiação (Plano Ouro).',
                    accentGold: true,
                    onTap: () => context.push(AppRoutes.premiacoes),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star_outline, size: 36, color: scheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pontuação', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Vencedor correto: 3 pts. Placar exato: 5 pts. Errou: 0.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

/// Bloco editorial + acento “evento” (faixa verde + traço ouro, direção visual v1).
class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Copa do Mundo 2026',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Palpite, acompanhe o ranking e veja a pontuação após cada jogo.',
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentGold = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accentGold;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = accentGold ? scheme.secondary : scheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: accentGold ? scheme.secondary.withValues(alpha: 0.85) : scheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Icon(icon, size: 34, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
