import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_error_view.dart';
import 'app_router.dart';

/// Ecrã de erro de navegação (rota inválida ou falha do router), alinhado ao estado “router error” da direção visual.
class RouterErrorScreen extends StatelessWidget {
  const RouterErrorScreen({
    super.key,
    required this.uri,
    this.error,
  });

  final Uri uri;
  final Object? error;

  void _goHome(BuildContext context) {
    final target = AppRouter.auth.isLoggedIn ? AppRoutes.inicio : AppRoutes.login;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = StringBuffer()
      ..writeln('O endereço pode estar incorreto ou a página foi movida.')
      ..writeln()
      ..write(uri.toString());
    if (error != null) {
      detail
        ..writeln()
        ..write(error);
    }

    return Scaffold(
      body: SafeArea(
        child: AppErrorView(
          title: 'Não encontrámos esta página',
          message: detail.toString(),
          icon: Icons.travel_explore_outlined,
          iconColor: scheme.secondary,
          primaryLabel: AppRouter.auth.isLoggedIn ? 'Ir para o início' : 'Ir para o login',
          primaryIcon: AppRouter.auth.isLoggedIn ? Icons.home_outlined : Icons.login,
          onPrimary: () => _goHome(context),
          secondaryLabel: context.canPop() ? 'Voltar' : 'Fechar',
          secondaryIcon: context.canPop() ? Icons.arrow_back : Icons.close,
          onSecondary: () {
            if (context.canPop()) {
              context.pop();
            } else {
              _goHome(context);
            }
          },
        ),
      ),
    );
  }
}
