import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/branding_logo.dart';

/// Landing inicial (mockup 01): fundo escuro, marca, CTAs e rodapé estático.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppRouter.auth.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: ListenableBuilder(
                      listenable: AppRouter.auth,
                      builder: (context, _) {
                        final auth = AppRouter.auth;
                        final loading = !auth.initialized;
                        final showCtas = auth.initialized && !auth.isLoggedIn;

                        return Center(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Copa 2026',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  const BrandingLogo(height: 96),
                                  const SizedBox(height: 16),
                                  Text(
                                    'BOLÃO',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Seja o campeão dos palpites na Copa do Mundo FIFA 2026. '
                                    'Crie seu grupo, desafie amigos e acompanhe a emoção!',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          height: 1.45,
                                        ),
                                  ),
                                  SizedBox(height: loading ? 28 : 32),
                                  if (loading)
                                    const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (showCtas) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () => context.go(AppRoutes.register),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size.fromHeight(52),
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                        child: const Text(
                                          'CRIAR MEU BOLÃO',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => context.go(AppRoutes.login),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(52),
                                          side: const BorderSide(color: Colors.white, width: 1.5),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                        child: const Text(
                                          'FAZER LOGIN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  /// Fundo estilo estádio noite: gradiente + vinheta. Para foto full-bleed, adicionar
  /// `assets/splash/hero_splash.png` em [pubspec.yaml] e um [DecorationImage] aqui.
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBackground,
                const Color(0xFF0F172A),
                AppTheme.primary.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.black.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
