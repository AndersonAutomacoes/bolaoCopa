import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/widgets/selecao_flag_image.dart';

/// Lista de jogos da competição.
class JogosListScreen extends StatefulWidget {
  const JogosListScreen({super.key});

  @override
  State<JogosListScreen> createState() => _JogosListScreenState();
}

class _JogosListScreenState extends State<JogosListScreen> {
  late Future<List<JogoDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = BolaoApi.fetchJogos();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchJogos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.meusPalpites),
            icon: const Icon(Icons.edit_note, size: 20),
            label: const Text('Meus palpites'),
          ),
        ],
      ),
      body: FutureBuilder<List<JogoDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Erro ao carregar jogos',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhum jogo cadastrado ainda',
              subtitle:
                  'Quando um administrador incluir partidas, elas aparecerão nesta lista.',
              icon: Icons.sports_soccer_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final j = list[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelecaoFlagImage(bandeiraUrl: j.selecaoCasa.bandeiraUrl, width: 36, height: 26),
                      const SizedBox(width: 8),
                      SelecaoFlagImage(bandeiraUrl: j.selecaoFora.bandeiraUrl, width: 36, height: 26),
                    ],
                  ),
                  title: Text(
                    j.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${j.fase} · ${formatKickoff(j.kickoffAt)} · ${formatJogoStatus(j.status)}',
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
