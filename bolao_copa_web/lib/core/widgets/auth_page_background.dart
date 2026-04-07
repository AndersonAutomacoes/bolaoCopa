import 'package:flutter/material.dart';

/// Fundo comum às telas de login/cadastro (mockups): cinza claro + marca d’água.
class AuthPageBackground extends StatelessWidget {
  const AuthPageBackground({super.key});

  static const Color bg = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Center(
                  child: Opacity(
                    opacity: 0.035,
                    child: Icon(
                      Icons.sports_soccer,
                      size: 380,
                      color: Colors.black,
                    ),
                  ),
                ),
                Positioned(
                  top: 48,
                  right: 32,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Text(
                      'FIFA 2026',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: 28,
                  child: Transform.rotate(
                    angle: 0.14,
                    child: Text(
                      'FIFA 2026',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
