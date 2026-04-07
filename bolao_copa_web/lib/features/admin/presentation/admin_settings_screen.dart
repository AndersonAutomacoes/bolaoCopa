import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import 'admin_shell_layout.dart';

/// Configurações do painel admin (MVP: preferências locais e atalhos).
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AdminShellLayout(
      title: 'Configurações',
      navIndex: 3,
      child: ListView(
        padding: AppLayout.pagePaddingHV,
        children: [
          Text(
            'Painel administrativo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Gerir seleções, jogos e dados da competição. '
            'Alterações críticas devem ser validadas antes de produção.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Seleções'),
                  subtitle: const Text('Países e URLs de bandeiras'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.adminSelecoes),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sports_soccer_outlined),
                  title: const Text('Jogos'),
                  subtitle: const Text('Partidas, datas e estados'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.adminJogos),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Voltar à app principal'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => context.go(AppRoutes.inicio),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
