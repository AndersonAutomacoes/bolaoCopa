import 'package:flutter/material.dart';

/// Estado de erro padrão: ícone, título, detalhe opcional e até duas ações (primária preenchida + secundária contorno).
///
/// Use com [FutureBuilder] / chamadas async quando `snapshot.hasError`, ou em rotas inválidas.
/// [onRetry] e [retryLabel] são aliases de [onPrimary] e do rótulo do botão primário.
class AppErrorView extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables — aliases onPrimary/onRetry não podem ser const
  AppErrorView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.error_outline,
    this.iconColor,
    String primaryLabel = 'Tentar de novo',
    String? retryLabel,
    VoidCallback? onPrimary,
    VoidCallback? onRetry,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon,
  })  : _primaryLabel = retryLabel ?? primaryLabel,
        _onPrimary = onPrimary ?? onRetry;

  final String title;
  final String? message;
  final IconData icon;
  final Color? iconColor;
  final String _primaryLabel;
  final VoidCallback? _onPrimary;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? scheme.error;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: effectiveIconColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (_onPrimary != null || onSecondary != null) ...[
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (onSecondary != null && secondaryLabel != null)
                      secondaryIcon != null
                          ? OutlinedButton.icon(
                              onPressed: onSecondary,
                              icon: Icon(secondaryIcon, size: 20),
                              label: Text(secondaryLabel!),
                            )
                          : OutlinedButton(
                              onPressed: onSecondary,
                              child: Text(secondaryLabel!),
                            ),
                    if (_onPrimary != null)
                      primaryIcon != null
                          ? FilledButton.icon(
                              onPressed: _onPrimary,
                              icon: Icon(primaryIcon, size: 20),
                              label: Text(_primaryLabel),
                            )
                          : FilledButton(
                              onPressed: _onPrimary,
                              child: Text(_primaryLabel),
                            ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
