import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/ranking_item_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/ranking_rank_row.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ranking_table_header.dart';

class BolaoGruposScreen extends StatefulWidget {
  const BolaoGruposScreen({super.key});

  @override
  State<BolaoGruposScreen> createState() => _BolaoGruposScreenState();
}

class _BolaoGruposScreenState extends State<BolaoGruposScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _futureMine;
  late Future<List<Map<String, dynamic>>> _futurePublic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _futureMine = BolaoApi.fetchMeusBoloes();
      _futurePublic = BolaoApi.fetchBoloesPublicos();
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
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Bolões'),
        actions: AppShellAppBarActions.build(
          context,
          extra: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.onSurface,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Meus bolões'),
            Tab(text: 'Bolões públicos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MeusBoloesTab(
            future: _futureMine,
            onReload: _reload,
            onCriar: _criar,
            onEntrar: _entrar,
          ),
          _BoloesPublicosTab(future: _futurePublic, onReload: _reload),
        ],
      ),
    );
  }
}

class _MeusBoloesTab extends StatelessWidget {
  const _MeusBoloesTab({
    required this.future,
    required this.onReload,
    required this.onCriar,
    required this.onEntrar,
  });

  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onReload;
  final Future<void> Function() onCriar;
  final Future<void> Function() onEntrar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
        }
        if (snapshot.hasError) {
          return AppErrorView(
            title: 'Não foi possível carregar seus bolões',
            message: apiErrorMessage(snapshot.error),
            onPrimary: onReload,
          );
        }
        final list = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(child: FilledButton(onPressed: onCriar, child: const Text('Criar bolão'))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(onPressed: onEntrar, child: const Text('Entrar com código'))),
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
                      padding: AppLayout.pagePaddingHV,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final g = list[i];
                        final id = (g['id'] as num).toInt();
                        final nome = g['nome'] as String? ?? '';
                        final codigo = g['codigoConvite'] as String? ?? '';
                        final pub = g['publico'] as bool? ?? false;
                        return Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Código: $codigo${pub ? ' · Público' : ''}'),
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
    );
  }
}

class _BoloesPublicosTab extends StatelessWidget {
  const _BoloesPublicosTab({required this.future, required this.onReload});

  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
        }
        if (snapshot.hasError) {
          return AppErrorView(
            title: 'Não foi possível carregar bolões públicos',
            message: apiErrorMessage(snapshot.error),
            onPrimary: onReload,
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const AppEmptyState(
            title: 'Nenhum bolão público',
            subtitle: 'Quando um organizador marcar um bolão como público, ele aparecerá aqui.',
            icon: Icons.public_outlined,
          );
        }
        return ListView.separated(
          padding: AppLayout.pagePaddingHV,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final g = list[i];
            final id = (g['id'] as num).toInt();
            final nome = g['nome'] as String? ?? '';
            final codigo = g['codigoConvite'] as String? ?? '';
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Código de convite: $codigo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/boloes/$id/ranking', extra: nome),
              ),
            );
          },
        );
      },
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

class _BolaoRankingScreenState extends State<BolaoRankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RankingItemDto>> _futureRanking;
  late Future<Map<String, dynamic>> _futureBolao;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _bolaoIdParsed => int.tryParse(widget.bolaoId);

  Future<List<RankingItemDto>> _loadRanking() {
    final id = _bolaoIdParsed;
    if (id == null) {
      return Future.error(Exception('ID inválido'));
    }
    return BolaoApi.fetchBolaoRanking(id);
  }

  Future<Map<String, dynamic>> _loadBolao() {
    final id = _bolaoIdParsed;
    if (id == null) {
      return Future.error(Exception('ID inválido'));
    }
    return BolaoApi.fetchBolaoById(id);
  }

  void _reload() {
    setState(() {
      _futureRanking = _loadRanking();
      _futureBolao = _loadBolao();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final title = widget.bolaoNome != null && widget.bolaoNome!.trim().isNotEmpty
        ? widget.bolaoNome!.trim()
        : 'Bolão #${widget.bolaoId}';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(title),
        actions: AppShellAppBarActions.build(
          context,
          extra: [
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.onSurface,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Ranking'),
            Tab(text: 'Premiação'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<RankingItemDto>>(
            future: _futureRanking,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppListSkeleton.ranking(padding: AppLayout.pagePaddingAll);
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
                padding: AppLayout.pagePaddingHV,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineMuted),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ranking do bolão',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mesma ordenação do ranking global: pontos, placares exatos, data do primeiro palpite.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
          FutureBuilder<Map<String, dynamic>>(
            future: _futureBolao,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
              }
              if (snapshot.hasError) {
                return AppErrorView(
                  title: 'Não foi possível carregar o bolão',
                  message: apiErrorMessage(snapshot.error),
                  onPrimary: _reload,
                );
              }
              final g = snapshot.data ?? {};
              final texto = g['premiacaoTexto'] as String?;
              final nome = g['nome'] as String? ?? title;
              if (texto == null || texto.trim().isEmpty) {
                return AppEmptyState(
                  title: 'Premiação não definida',
                  subtitle:
                      'O organizador pode definir a premiação deste bolão (Plano Prata+). Veja como funciona na ajuda ou atualize quando o texto for publicado.',
                  icon: Icons.emoji_events_outlined,
                  actionLabel: 'Abrir ajuda',
                  onAction: () => context.push(AppRoutes.ajuda),
                );
              }
              return ListView(
                padding: AppLayout.pagePaddingHV,
                children: [
                  Text(
                    nome,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    texto,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
