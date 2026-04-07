import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branding_logo.dart';

/// Shell principal: navegação por abas (web/mobile) entre Início, Jogos, Ranking e Perfil.
///
/// Desktop (≥900px): [NavigationRail] escuro estilo mockup (ícone + rótulo, indicador verde).
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_soccer_outlined),
      selectedIcon: Icon(Icons.sports_soccer),
      label: 'Jogos',
    ),
    NavigationDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard),
      label: 'Ranking',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    if (useRail) {
      final railTheme = Theme.of(context).copyWith(
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: AppTheme.railBackground,
          indicatorColor: AppTheme.primary,
          selectedIconTheme: IconThemeData(color: AppTheme.railOnBackground, size: 24),
          unselectedIconTheme: IconThemeData(color: AppTheme.railMuted, size: 24),
          selectedLabelTextStyle: TextStyle(
            color: AppTheme.railOnBackground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: AppTheme.railMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

      return Theme(
        data: railTheme,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Row(
            children: [
              NavigationRail(
                extended: false,
                labelType: NavigationRailLabelType.all,
                minWidth: 88,
                groupAlignment: -1,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 28),
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.inicio),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          const BrandingLogo(height: 40),
                          const SizedBox(height: 12),
                          Text(
                            'BOLÃO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.railOnBackground,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'COPA 2026',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.railMuted,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onDestinationSelected,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Início'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sports_soccer_outlined),
                    selectedIcon: Icon(Icons.sports_soccer),
                    label: Text('Jogos'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.leaderboard_outlined),
                    selectedIcon: Icon(Icons.leaderboard),
                    label: Text('Ranking'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Perfil'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF334155)),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: Material(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations,
        ),
      ),
    );
  }
}
