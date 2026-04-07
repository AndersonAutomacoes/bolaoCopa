import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/oauth_bridge_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/jogos/presentation/jogo_detail_screen.dart';
import '../../features/jogos/presentation/jogos_list_screen.dart';
import '../../features/palpites/presentation/meu_palpite_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/ranking/presentation/ranking_screen.dart';
import '../../features/shell/presentation/main_scaffold.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_jogos_screen.dart';
import '../../features/admin/presentation/admin_selecoes_screen.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/help/presentation/ajuda_screen.dart';
import '../../features/notifications/presentation/in_app_notifications_screen.dart';
import '../../features/bolao_grupo/presentation/bolao_grupos_screen.dart';
import '../../features/premiacao/presentation/premiacao_screen.dart';
import '../../features/regras/presentation/regras_screen.dart';
import '../models/jogo_dto.dart';
import '../auth/app_auth.dart';
import 'router_error_screen.dart';

/// Igual ao contentor `indexedStack` do go_router, mas força cada ramo a preencher o viewport.
/// No Web, sem isto o [Offstage] + [Navigator] pode deixar hit-test com “no size” e rebentar o [MouseTracker].
Widget _shellIndexedStackWithExpandedBranches(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  return IndexedStack(
    index: navigationShell.currentIndex,
    sizing: StackFit.expand,
    children: List<Widget>.generate(children.length, (int i) {
      final active = navigationShell.currentIndex == i;
      return Offstage(
        offstage: !active,
        child: TickerMode(
          enabled: active,
          child: SizedBox.expand(child: children[i]),
        ),
      );
    }),
  );
}

/// Fluxo principal da webapp:
///
/// 1. [SplashScreen] — bootstrap da sessão; landing pública com CTAs (login/registo).
/// 2. Não autenticado → [LoginScreen] ou [RegisterScreen] a partir da splash ou URL direta.
/// 3. Autenticado → shell com abas: Início, Jogos, Ranking, Perfil.
/// 4. [JogosListScreen] → [JogoDetailScreen] (ver jogo + registrar/editar palpite).
/// 5. [MeuPalpiteScreen] — lista consolidada dos palpites do usuário (atalho na home e na app bar).
/// Rotas de bolão podem receber `extra` (nome) para títulos amigáveis no ranking.
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
        if (loc == AppRoutes.splash ||
            loc == AppRoutes.oauthBridge ||
            loc == AppRoutes.recuperarSenha ||
            loc == AppRoutes.redefinirSenha) {
          return null;
        }
        return AppRoutes.splash;
      }
      if (loc == AppRoutes.splash) {
        return auth.isLoggedIn ? AppRoutes.inicio : null;
      }
      final publicAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.splash ||
          loc == AppRoutes.recuperarSenha ||
          loc == AppRoutes.redefinirSenha ||
          loc == AppRoutes.oauthBridge;
      if (!auth.isLoggedIn && !publicAuthRoute) {
        return AppRoutes.login;
      }
      final isAuthShellRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.recuperarSenha ||
          loc == AppRoutes.redefinirSenha;
      if (auth.isLoggedIn && isAuthShellRoute) {
        return AppRoutes.inicio;
      }
      if (auth.isLoggedIn) {
        final path = state.uri.path;
        if (path.startsWith(AppRoutes.boloes) && !auth.tierPrataOrAbove) {
          return AppRoutes.inicio;
        }
        if (path.startsWith(AppRoutes.premiacoes) && !auth.tierOuro) {
          return AppRoutes.inicio;
        }
      }
      return null;
    },
    errorBuilder: (context, state) => RouterErrorScreen(
      uri: state.uri,
      error: state.error,
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
      GoRoute(
        path: AppRoutes.recuperarSenha,
        name: AppRoutes.recuperarSenhaName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.redefinirSenha,
        name: AppRoutes.redefinirSenhaName,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.oauthBridge,
        name: AppRoutes.oauthBridgeName,
        builder: (context, state) => OAuthBridgeScreen(uri: state.uri),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: _shellIndexedStackWithExpandedBranches,
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
      GoRoute(
        path: AppRoutes.regras,
        name: AppRoutes.regrasName,
        builder: (context, state) => const RegrasScreen(),
      ),
      GoRoute(
        path: AppRoutes.ajuda,
        name: AppRoutes.ajudaName,
        builder: (context, state) => const AjudaScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificacoes,
        name: AppRoutes.notificacoesName,
        builder: (context, state) => const InAppNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: AppRoutes.adminName,
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'selecoes',
            name: AppRoutes.adminSelecoesName,
            builder: (context, state) => const AdminSelecoesScreen(),
          ),
          GoRoute(
            path: 'jogos',
            name: AppRoutes.adminJogosName,
            builder: (context, state) => const AdminJogosScreen(),
          ),
          GoRoute(
            path: 'configuracoes',
            name: AppRoutes.adminConfiguracoesName,
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.boloes,
        name: AppRoutes.boloesName,
        builder: (context, state) => const BolaoGruposScreen(),
        routes: [
          GoRoute(
            path: ':bolaoId/ranking',
            name: AppRoutes.bolaoRankingName,
            builder: (context, state) {
              final id = state.pathParameters['bolaoId'] ?? '';
              final nome = state.extra is String ? state.extra as String : null;
              return BolaoRankingScreen(bolaoId: id, bolaoNome: nome);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.premiacoes,
        name: AppRoutes.premiacoesName,
        builder: (context, state) => const PremiacaoScreen(),
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
  static const recuperarSenha = '/recuperar-senha';
  static const recuperarSenhaName = 'recuperarSenha';
  static const redefinirSenha = '/redefinir-senha';
  static const redefinirSenhaName = 'redefinirSenha';
  static const oauthBridge = '/oauth-bridge';
  static const oauthBridgeName = 'oauthBridge';
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
  static const admin = '/admin';
  static const adminName = 'admin';
  static const adminSelecoes = '/admin/selecoes';
  static const adminSelecoesName = 'adminSelecoes';
  static const adminJogos = '/admin/jogos';
  static const adminJogosName = 'adminJogos';
  static const boloes = '/boloes';
  static const boloesName = 'boloes';
  static const bolaoRankingName = 'bolaoRanking';
  static const premiacoes = '/premiacoes';
  static const premiacoesName = 'premiacoes';
  static const regras = '/regras';
  static const regrasName = 'regras';
  static const ajuda = '/ajuda';
  static const ajudaName = 'ajuda';
  static const notificacoes = '/notificacoes';
  static const notificacoesName = 'notificacoes';
  static const adminConfiguracoes = '/admin/configuracoes';
  static const adminConfiguracoesName = 'adminConfiguracoes';
}
