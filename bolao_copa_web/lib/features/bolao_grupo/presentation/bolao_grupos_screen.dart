import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/ranking_item_dto.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/widgets/ranking_rank_row.dart';
import '../../../core/widgets/ranking_table_header.dart';

class BolaoGruposScreen extends StatefulWidget {
  const BolaoGruposScreen({super.key});

  @override
  State<BolaoGruposScreen> createState() => _BolaoGruposScreenState();
}

class _BolaoGruposScreenState extends State<BolaoGruposScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchMeusBoloes();
    });
  }

  Future<void> _criar() async {
    final nomeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo bolão (Plano Prata+)'),
        content: TextField(
          controller: nomeCtrl,
          decoration: const InputDecoration(labelText: 'Nome do bolão'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Criar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await BolaoApi.createBolaoGrupo(nome: nomeCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bolão criado.')));
        _reload();
      }
    } catch (e) {
      if (e is ApiException && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _entrar() async {
    final codigoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entrar com código'),
        content: TextField(
          controller: codigoCtrl,
          decoration: const InputDecoration(labelText: 'Código de convite'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Entrar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await BolaoApi.joinBolaoGrupo(codigoConvite: codigoCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você entrou no bolão.')));
        _reload();
      }
    } catch (e) {
      if (e is ApiException && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Bolões privados'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar seus bolões',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: _criar, child: const Text('Criar bolão'))),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton(onPressed: _entrar, child: const Text('Entrar'))),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const AppEmptyState(
                        title: 'Nenhum bolão ainda',
                        subtitle: 'Crie um bolão ou entre com um código de convite.',
                        icon: Icons.groups_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final g = list[i];
                          final id = (g['id'] as num).toInt();
                          final nome = g['nome'] as String? ?? '';
                          final codigo = g['codigoConvite'] as String? ?? '';
                          return Card(
                            child: ListTile(
                              title: Text(nome),
                              subtitle: Text('Código: $codigo'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/boloes/$id/ranking', extra: nome),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BolaoRankingScreen extends StatefulWidget {
  const BolaoRankingScreen({super.key, required this.bolaoId, this.bolaoNome});

  final String bolaoId;
  final String? bolaoNome;

  @override
  State<BolaoRankingScreen> createState() => _BolaoRankingScreenState();
}

class _BolaoRankingScreenState extends State<BolaoRankingScreen> {
  late Future<List<RankingItemDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRanking();
  }

  Future<List<RankingItemDto>> _loadRanking() {
    final id = int.tryParse(widget.bolaoId);
    if (id == null) {
      return Future.error(Exception('ID inválido'));
    }
    return BolaoApi.fetchBolaoRanking(id);
  }

  void _reload() {
    setState(() {
      _future = _loadRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(
          widget.bolaoNome != null && widget.bolaoNome!.trim().isNotEmpty
              ? 'Ranking · ${widget.bolaoNome!.trim()}'
              : 'Ranking do bolão #${widget.bolaoId}',
        ),
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
              title: 'Não foi possível carregar o ranking deste bolão',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhum dado de ranking',
              subtitle: 'Ainda não há pontuação para os membros deste bolão.',
              icon: Icons.groups_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const RankingTableHeader(),
              const SizedBox(height: 8),
              ...list.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RankingRankRow(item: r),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
