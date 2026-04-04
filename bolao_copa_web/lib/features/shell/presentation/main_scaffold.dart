import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell principal: navegação por abas (web/mobile) entre Início, Jogos, Ranking e Perfil.
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
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              minExtendedWidth: 280,
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
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
