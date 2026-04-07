import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';

/// Ajuda e atalhos (MVP: conteúdo estático + link às regras).
class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: AppLayout.pagePaddingHV,
        children: [
          Text(
            'Como usar o Bolão Copa',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'Palpite antes do apito inicial, acompanhe o ranking geral e nos seus bolões, '
            'e confira a premiação do seu plano quando disponível.',
            style: t.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 24),
          _LinkTile(
            icon: Icons.rule_folder_outlined,
            title: 'Regras do bolão',
            subtitle: 'Pontuação, prazos e conduta',
            onTap: () => context.push(AppRoutes.regras),
          ),
          _LinkTile(
            icon: Icons.sports_soccer_outlined,
            title: 'Jogos e palpites',
            subtitle: 'Lista de jogos e registo de placares',
            onTap: () => context.go(AppRoutes.jogos),
          ),
          _LinkTile(
            icon: Icons.leaderboard_outlined,
            title: 'Ranking',
            subtitle: 'Classificação geral e por bolão',
            onTap: () => context.go(AppRoutes.ranking),
          ),
          const SizedBox(height: 24),
          Text(
            'Suporte',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Em caso de dúvidas ou problemas técnicos, contacte o administrador da sua competição.',
            style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
