import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/ranking_item_dto.dart';
import '../../../core/models/user_profile_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/widgets/ranking_rank_row.dart';
import '../../../core/widgets/ranking_table_header.dart';

/// Ranking: aba **Geral** (Global / Semanal / Mensal) e **Meus bolões** (lista → ranking do bolão).
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with TickerProviderStateMixin {
  late Future<({List<RankingItemDto> items, UserProfileDto? me})> _future;
  late TabController _mainTabController;
  late TabController _periodTabController;
  int _lastPeriodIndex = 0;
  String? _nomeFiltro;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _periodTabController = TabController(length: 3, vsync: this);
    _periodTabController.addListener(_onPeriodChanged);
    _future = _load();
  }

  void _onPeriodChanged() {
    if (_periodTabController.indexIsChanging) return;
    if (_periodTabController.index == _lastPeriodIndex) return;
    _lastPeriodIndex = _periodTabController.index;
    setState(() {
      _future = _load();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _periodTabController.dispose();
    super.dispose();
  }

  String _periodQueryParam() {
    switch (_periodTabController.index) {
      case 1:
        return 'WEEK';
      case 2:
        return 'MONTH';
      default:
        return 'GLOBAL';
    }
  }

  Future<({List<RankingItemDto> items, UserProfileDto? me})> _load() async {
    final items = await BolaoApi.fetchRanking(
      period: _periodQueryParam(),
      nome: _nomeFiltro,
    );
    UserProfileDto? me;
    try {
      me = await BolaoApi.fetchProfile();
    } catch (_) {}
    return (items: items, me: me);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _nomeFiltro ?? '');
    final result = await showDialog<_SearchResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrar ranking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome ou email',
            hintText: 'Parte do nome ou email',
          ),
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => Navigator.pop(
            ctx,
            _SearchResult(clear: false, text: controller.text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, const _SearchResult(clear: true)),
            child: const Text('Limpar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              _SearchResult(clear: false, text: controller.text),
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.clear) {
        _nomeFiltro = null;
      } else {
        final t = result.text?.trim();
        _nomeFiltro = (t == null || t.isEmpty) ? null : t;
      }
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ranking',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: AppShellAppBarActions.build(
          context,
          extra: [
            Semantics(
              label: 'Pesquisar ranking por nome ou email',
              button: true,
              child: IconButton(
                tooltip: 'Pesquisar por nome ou email',
                onPressed: _openSearch,
                icon: Icon(
                  _nomeFiltro != null && _nomeFiltro!.isNotEmpty ? Icons.manage_search : Icons.search,
                ),
              ),
            ),
            Semantics(
              label: 'Atualizar ranking',
              button: true,
              child: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _mainTabController,
          labelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.onSurface,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Meus bolões'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_nomeFiltro != null && _nomeFiltro!.isNotEmpty)
                Material(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtro: “$_nomeFiltro”',
                            style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Limpar filtro',
                          onPressed: () {
                            setState(() {
                              _nomeFiltro = null;
                              _future = _load();
                            });
                          },
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                child: TabBar(
                  controller: _periodTabController,
                  labelStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: t.labelLarge?.copyWith(fontWeight: FontWeight.w500),
                  labelColor: scheme.onSurface,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Global'),
                    Tab(text: 'Semanal'),
                    Tab(text: 'Mensal'),
                  ],
                ),
              ),
              Expanded(
                child: _RankingGeralTab(
                  future: _future,
                  onRetry: _reload,
                  periodLabel: switch (_periodTabController.index) {
                    1 => 'semana',
                    2 => 'mês',
                    _ => null,
                  },
                ),
              ),
            ],
          ),
          const _RankingMeusBoloesTab(),
        ],
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({required this.clear, this.text});

  final bool clear;
  final String? text;
}

class _RankingMeusBoloesTab extends StatefulWidget {
  const _RankingMeusBoloesTab();

  @override
  State<_RankingMeusBoloesTab> createState() => _RankingMeusBoloesTabState();
}

class _RankingMeusBoloesTabState extends State<_RankingMeusBoloesTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = BolaoApi.fetchMeusBoloes();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchMeusBoloes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
        }
        if (snapshot.hasError) {
          return AppErrorView(
            title: 'Não foi possível carregar seus bolões',
            message: apiErrorMessage(snapshot.error),
            onPrimary: _reload,
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return AppEmptyState(
            title: 'Nenhum bolão ainda',
            subtitle: 'Crie um bolão ou entre com um código na área Bolões.',
            icon: Icons.groups_outlined,
            actionLabel: 'Abrir bolões',
            onAction: () => context.push(AppRoutes.boloes),
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
                subtitle: Text('Código: $codigo'),
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

class _RankingGeralTab extends StatelessWidget {
  const _RankingGeralTab({
    required this.future,
    required this.onRetry,
    this.periodLabel,
  });

  final Future<({List<RankingItemDto> items, UserProfileDto? me})> future;
  final VoidCallback onRetry;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<RankingItemDto> items, UserProfileDto? me})>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppListSkeleton.ranking(padding: AppLayout.pagePaddingAll);
        }
        if (snapshot.hasError) {
          return AppErrorView(
            title: 'Não foi possível carregar o ranking',
            message: apiErrorMessage(snapshot.error),
            onPrimary: onRetry,
          );
        }
        final data = snapshot.data!;
        final list = data.items;
        final me = data.me;
        if (list.isEmpty) {
          return AppEmptyState(
            title: periodLabel != null ? 'Ninguém neste período' : 'Ranking ainda vazio',
            subtitle: periodLabel != null
                ? 'Não há pontos de jogos com data de início neste $periodLabel, ou ainda não há palpites contabilizados.'
                : 'Quando houver palpites e jogos finalizados, a classificação aparecerá aqui.',
            icon: Icons.leaderboard_outlined,
          );
        }

        RankingItemDto? myRow;
        if (me != null) {
          for (final e in list) {
            if (e.userId == me.userId) {
              myRow = e;
              break;
            }
          }
        }

        final scheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppLayout.pagePaddingHV,
                children: [
                  const RankingTableHeader(),
                  const SizedBox(height: 10),
                  ...list.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RankingRankRow(item: e),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: scheme.surface,
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.person_pin_circle_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        myRow != null
                            ? 'Sua posição: ${myRow.posicao}º — ${myRow.totalPontos} pts'
                            : 'Sua posição: ainda não classificado',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
