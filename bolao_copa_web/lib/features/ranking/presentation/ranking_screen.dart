import 'package:flutter/material.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/ranking_item_dto.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/widgets/ranking_rank_row.dart';
import '../../../core/widgets/ranking_table_header.dart';

/// Ranking geral (ordenado no servidor).
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
    setState(() {
      _future = BolaoApi.fetchRanking();
    });
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
            return const AppListSkeleton.ranking();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar o ranking',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Ranking ainda vazio',
              subtitle:
                  'Quando houver palpites e jogos finalizados, a classificação aparecerá aqui.',
              icon: Icons.leaderboard_outlined,
            );
          }
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ordenação: pontos totais; em empate, mais placares exatos; persistindo o empate, quem palpitou primeiro.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              const RankingTableHeader(),
              const SizedBox(height: 8),
              ...list.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RankingRankRow(item: e),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
