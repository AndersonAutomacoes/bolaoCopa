import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/in_app_notification_store.dart';
import '../../../core/theme/app_layout.dart';

class _NotifItem {
  const _NotifItem({required this.id, required this.title, required this.body, required this.time});

  final String id;
  final String title;
  final String body;
  final String time;
}

/// Centro de notificações in-app (lista estática + estado lido em [SharedPreferences]).
class InAppNotificationsScreen extends StatefulWidget {
  const InAppNotificationsScreen({super.key});

  @override
  State<InAppNotificationsScreen> createState() => _InAppNotificationsScreenState();
}

class _InAppNotificationsScreenState extends State<InAppNotificationsScreen> {
  late Future<Set<String>> _read;

  static const _items = <_NotifItem>[
    _NotifItem(
      id: InAppNotificationIds.palpiteFechado,
      title: 'Prazo de palpite',
      body: 'Lembrete: envie o palpite antes do início do jogo.',
      time: 'Hoje',
    ),
    _NotifItem(
      id: InAppNotificationIds.jogoResultado,
      title: 'Resultados',
      body: 'Quando um jogo termina, o ranking é atualizado automaticamente.',
      time: 'Ontem',
    ),
    _NotifItem(
      id: InAppNotificationIds.rankingAtualizado,
      title: 'Ranking',
      body: 'Acompanhe a sua posição no separador Ranking.',
      time: 'Esta semana',
    ),
    _NotifItem(
      id: InAppNotificationIds.bolaoConvite,
      title: 'Bolões',
      body: 'Use o código de convite para entrar num bolão privado.',
      time: '—',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _read = InAppNotificationStore.readIds();
  }

  Future<void> _refresh() async {
    setState(() {
      _read = InAppNotificationStore.readIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await InAppNotificationStore.markAllRead(_items.map((e) => e.id));
              await _refresh();
            },
            child: const Text('Marcar todas como lidas'),
          ),
        ],
      ),
      body: FutureBuilder<Set<String>>(
        future: _read,
        builder: (context, snap) {
          final read = snap.data ?? {};
          return ListView.separated(
            padding: AppLayout.pagePaddingHV,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = _items[i];
              final isUnread = !read.contains(n.id);
              return Material(
                color: isUnread ? scheme.primaryContainer.withValues(alpha: 0.35) : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await InAppNotificationStore.markRead(n.id);
                    await _refresh();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUnread)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 10),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    n.time,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.body,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
