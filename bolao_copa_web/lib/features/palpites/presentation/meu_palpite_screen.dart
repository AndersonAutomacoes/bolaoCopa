import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/palpite_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';

/// Lista consolidada dos palpites do usuário.
class MeuPalpiteScreen extends StatefulWidget {
  const MeuPalpiteScreen({super.key});

  @override
  State<MeuPalpiteScreen> createState() => _MeuPalpiteScreenState();
}

class _MeuPalpiteScreenState extends State<MeuPalpiteScreen> {
  late Future<List<PalpiteDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = BolaoApi.fetchMeusPalpites();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchMeusPalpites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Meus palpites'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
        ],
      ),
      body: FutureBuilder<List<PalpiteDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar seus palpites',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return AppEmptyState(
              title: 'Você ainda não tem palpites registrados',
              subtitle: 'Abra a lista de jogos e envie seus palpites antes do apito inicial.',
              icon: Icons.edit_note_outlined,
              actionLabel: 'Ver jogos e palpitar',
              onAction: () => context.go(AppRoutes.jogos),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = list[i];
              final j = p.jogo;
              return Card(
                child: ListTile(
                  title: Text(j.titulo),
                  subtitle: Text(
                    'Palpite: ${p.golsCasaPalpite} x ${p.golsForaPalpite} · ${formatJogoStatus(j.status)} · ${formatKickoff(j.kickoffAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
