import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/models/ranking_item_dto.dart';

/// GET /api/v1/ranking
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<RankingItemDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = BolaoApi.fetchRanking();
  }

  void _reload() {
    setState(() => _future = BolaoApi.fetchRanking());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
        ],
      ),
      body: FutureBuilder<List<RankingItemDto>>(
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'GET /api/v1/ranking — ordenação no backend (pontos, acertos exatos, primeiro palpite).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Ranking vazio. Palpites e resultados oficiais atualizam a materialized view.'),
                )
              else
                ...list.map(
                  (e) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${e.posicao}')),
                      title: Text(e.nome?.isNotEmpty == true ? e.nome! : e.email),
                      subtitle: Text('${e.totalPontos} pts · ${e.totalAcertosExatos} placares exatos'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
