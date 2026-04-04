import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/palpite_dto.dart';

/// GET /api/v1/palpites/me
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
    setState(() => _future = BolaoApi.fetchMeusPalpites());
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
                    Text(msg, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Tentar de novo')),
                  ],
                ),
              ),
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Você ainda não tem palpites registrados.'),
              ),
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
                    'Palpite: ${p.golsCasaPalpite} x ${p.golsForaPalpite} · ${j.status} · ${formatKickoff(j.kickoffAt)}',
                  ),
                  trailing: const Icon(Icons.sports_soccer),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
