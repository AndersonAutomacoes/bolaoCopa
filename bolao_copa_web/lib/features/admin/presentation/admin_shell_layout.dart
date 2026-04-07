import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/models/user_profile_dto.dart';
import '../../../core/notifications/in_app_notification_store.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_profile_avatar.dart';

/// Layout comum às telas admin (mockup: sidebar clara + área principal).
class AdminShellLayout extends StatelessWidget {
  const AdminShellLayout({
    super.key,
    required this.title,
    required this.navIndex,
    required this.child,
    this.headerActions = const [],
  });

  /// 0 painel, 1 seleções, 2 jogos.
  final int navIndex;
  final String title;
  final Widget child;
  final List<Widget> headerActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminSidebar(navIndex: navIndex),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: scheme.surface,
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Pesquisar...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Ajuda',
                          onPressed: () => context.push(AppRoutes.ajuda),
                          icon: const Icon(Icons.help_outline),
                        ),
                        FutureBuilder<int>(
                          future: InAppNotificationStore.unreadCount(InAppNotificationIds.allDemo),
                          builder: (context, snap) {
                            final unread = snap.data ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  tooltip: 'Notificações',
                                  onPressed: () => context.push(AppRoutes.notificacoes),
                                  icon: const Icon(Icons.notifications_outlined),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const _AdminHeaderUserBlock(),
                        if (headerActions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ...headerActions,
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminHeaderUserBlock extends StatefulWidget {
  const _AdminHeaderUserBlock();

  @override
  State<_AdminHeaderUserBlock> createState() => _AdminHeaderUserBlockState();
}

class _AdminHeaderUserBlockState extends State<_AdminHeaderUserBlock> {
  late Future<UserProfileDto> _future;

  @override
  void initState() {
    super.initState();
    _future = BolaoApi.fetchProfile();
  }

  String _primeiroNome(String fullName) {
    final p = fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (p.isEmpty) return 'Conta';
    return p.first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return FutureBuilder<UserProfileDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('…', style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  Text(
                    'Painel',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Administrador',
                    style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    'Painel',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          );
        }
        final p = snapshot.data!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserProfileAvatarDisplay(profile: p, radius: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _primeiroNome(p.fullName),
                  style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Text(
                  'Painel',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.navIndex});

  final int navIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.dashboard_customize, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GESTOR BOLÃO',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            _NavEntry(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: 'Início',
              selected: navIndex == 0,
              accent: const Color(0xFF2563EB),
              onTap: () => context.go(AppRoutes.admin),
            ),
            _NavEntry(
              icon: Icons.flag_outlined,
              selectedIcon: Icons.flag,
              label: 'Seleções',
              selected: navIndex == 1,
              accent: AppTheme.primary,
              onTap: () => context.go(AppRoutes.adminSelecoes),
            ),
            _NavEntry(
              icon: Icons.sports_soccer_outlined,
              selectedIcon: Icons.sports_soccer,
              label: 'Jogos',
              selected: navIndex == 2,
              accent: AppTheme.primary,
              onTap: () => context.go(AppRoutes.adminJogos),
            ),
            _NavEntry(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Configurações',
              selected: navIndex == 3,
              accent: AppTheme.primary,
              onTap: () => context.go(AppRoutes.adminConfiguracoes),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                await AppRouter.auth.logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Icon(selected ? selectedIcon : icon, color: selected ? accent : scheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected ? accent : scheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
