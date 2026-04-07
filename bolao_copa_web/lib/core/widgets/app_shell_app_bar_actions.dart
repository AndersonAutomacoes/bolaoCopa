import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../notifications/in_app_notification_store.dart';
import '../router/app_router.dart';
import 'profile_account_menu_button.dart';

/// Ações de AppBar alinhadas ao mockup: notificações (com indicador) + menu de conta.
///
/// Use [extra] para ícones adicionais antes deste bloco (ex.: atualizar).
abstract final class AppShellAppBarActions {
  static List<Widget> build(
    BuildContext context, {
    List<Widget> extra = const [],
  }) {
    final scheme = Theme.of(context).colorScheme;
    return [
      ...extra,
      FutureBuilder<int>(
        future: InAppNotificationStore.unreadCount(InAppNotificationIds.allDemo),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return IconButton(
            tooltip: 'Notificações',
            onPressed: () => context.push(AppRoutes.notificacoes),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unread > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      const ProfileAccountMenuButton(),
    ];
  }
}
