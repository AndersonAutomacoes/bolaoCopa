import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/jogos/presentation/jogo_detail_screen.dart';
import '../../features/jogos/presentation/jogos_list_screen.dart';
import '../../features/palpites/presentation/meu_palpite_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/ranking/presentation/ranking_screen.dart';
import '../../features/shell/presentation/main_scaffold.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../models/jogo_dto.dart';
import '../auth/app_auth.dart';

/// Fluxo principal da webapp:
///
/// 1. [SplashScreen] — verifica sessão (token).
/// 2. Não autenticado → [LoginScreen] ou [RegisterScreen].
/// 3. Autenticado → shell com abas: Início, Jogos, Ranking, Perfil.
/// 4. [JogosListScreen] → [JogoDetailScreen] (ver jogo + registrar/editar palpite).
/// 5. [MeuPalpiteScreen] — lista consolidada dos palpites do usuário (atalho na home e na app bar).
///
/// Rotas nomeadas para deep link e testes.
abstract final class AppRouter {
  static final AppAuth auth = AppAuth();

  static final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

  static GoRouter get config => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;
      // No navegador a URL inicial costuma ser "/" — sem esta rota, nada corresponde e a tela fica em branco.
      if (loc == '/' || loc.isEmpty) {
        return AppRoutes.splash;
      }
      if (!auth.initialized) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (loc == AppRoutes.splash) {
        return auth.isLoggedIn ? AppRoutes.inicio : AppRoutes.login;
      }
      final loggingIn = loc == AppRoutes.login || loc == AppRoutes.register;
      if (!auth.isLoggedIn && !loggingIn) {
        return AppRoutes.login;
      }
      if (auth.isLoggedIn && loggingIn) {
        return AppRoutes.inicio;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'Rota ou erro de navegação.\nURI: ${state.uri}\n${state.error ?? ""}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inicio,
                name: AppRoutes.inicioName,
                pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jogos,
                name: AppRoutes.jogosName,
                pageBuilder: (context, state) => const NoTransitionPage(child: JogosListScreen()),
                routes: [
                  GoRoute(
                    path: ':jogoId',
                    name: AppRoutes.jogoDetalheName,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['jogoId'] ?? '';
                      final extra = state.extra;
                      final initial = extra is JogoDto ? extra : null;
                      return NoTransitionPage(
                        child: JogoDetailScreen(jogoId: id, initialJogo: initial),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ranking,
                name: AppRoutes.rankingName,
                pageBuilder: (context, state) => const NoTransitionPage(child: RankingScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.perfil,
                name: AppRoutes.perfilName,
                pageBuilder: (context, state) => const NoTransitionPage(child: PerfilScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.meusPalpites,
        name: AppRoutes.meusPalpitesName,
        builder: (context, state) => const MeuPalpiteScreen(),
      ),
    ],
  );
}

abstract final class AppRoutes {
  static const splash = '/splash';
  static const splashName = 'splash';
  static const login = '/login';
  static const loginName = 'login';
  static const register = '/register';
  static const registerName = 'register';
  static const inicio = '/inicio';
  static const inicioName = 'inicio';
  static const jogos = '/jogos';
  static const jogosName = 'jogos';
  static const jogoDetalheName = 'jogoDetalhe';
  static const ranking = '/ranking';
  static const rankingName = 'ranking';
  static const perfil = '/perfil';
  static const perfilName = 'perfil';
  static const meusPalpites = '/meus-palpites';
  static const meusPalpitesName = 'meusPalpites';
}
