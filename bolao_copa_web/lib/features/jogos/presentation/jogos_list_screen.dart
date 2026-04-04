import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/router/app_router.dart';

/// Lista de jogos via GET /api/v1/jogos.
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : '${snapshot.error}';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erro ao carregar jogos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SelectableText(msg, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Tentar de novo')),
                  ],
                ),
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nenhum jogo cadastrado. Um administrador pode criar jogos na API (POST /api/v1/jogos).',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(
                    j.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${j.fase} · ${formatKickoff(j.kickoffAt)} · ${j.status}',
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
