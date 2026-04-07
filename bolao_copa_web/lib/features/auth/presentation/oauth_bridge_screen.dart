import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// Recebe tokens após OAuth2 no backend e grava a sessão local.
class OAuthBridgeScreen extends StatefulWidget {
  const OAuthBridgeScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<OAuthBridgeScreen> createState() => _OAuthBridgeScreenState();
}

class _OAuthBridgeScreenState extends State<OAuthBridgeScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    await AppRouter.auth.bootstrap();
    if (!mounted) return;
    final q = widget.uri.queryParameters;
    final access = q['accessToken'];
    final refresh = q['refreshToken'];
    if (access == null || access.isEmpty) {
      setState(() => _error = 'Resposta OAuth sem token. Configure GOOGLE_CLIENT_ID / FACEBOOK_CLIENT_ID no servidor.');
      return;
    }
    await AppRouter.auth.applyOAuthTokens(access, refresh);
    if (!mounted) return;
    context.go(AppRoutes.inicio);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go(AppRoutes.login), child: const Text('Voltar ao login')),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
