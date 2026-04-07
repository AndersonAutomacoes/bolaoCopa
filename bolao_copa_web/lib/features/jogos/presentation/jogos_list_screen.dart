import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;

/// Lista de jogos da competição (abas por fase + cartões estilo mockup).
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'JOGOS',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        actions: AppShellAppBarActions.build(
          context,
          extra: [
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<JogoDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
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
          return _JogosListLoadedView(jogos: list);
        },
      ),
    );
  }
}

List<String> _orderedPhases(List<JogoDto> jogos) {
  final seen = <String>{};
  final out = <String>[];
  for (final j in jogos) {
    if (seen.add(j.fase)) out.add(j.fase);
  }
  return out;
}

bool _samePhaseLists(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _JogosListLoadedView extends StatefulWidget {
  const _JogosListLoadedView({required this.jogos});

  final List<JogoDto> jogos;

  @override
  State<_JogosListLoadedView> createState() => _JogosListLoadedViewState();
}

class _JogosListLoadedViewState extends State<_JogosListLoadedView>
    with SingleTickerProviderStateMixin {
  late List<String> _phases;
  TabController? _tabController;

  void _syncTabs() {
    final next = _orderedPhases(widget.jogos);
    if (_tabController != null && _samePhaseLists(_phases, next)) {
      return;
    }
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _phases = next;
    _tabController = TabController(length: 1 + _phases.length, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController == null) return;
    if (_tabController!.indexIsChanging) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _phases = _orderedPhases(widget.jogos);
    _tabController = TabController(length: 1 + _phases.length, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _JogosListLoadedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jogos != widget.jogos) {
      _syncTabs();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  List<JogoDto> get _filtered {
    final c = _tabController;
    if (c == null) return widget.jogos;
    final i = c.index;
    if (i == 0) return widget.jogos;
    final fase = _phases[i - 1];
    return widget.jogos.where((j) => j.fase == fase).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tc = _tabController;
    if (tc == null) {
      return const SizedBox.shrink();
    }

    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: tc,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            indicatorWeight: 3,
            tabs: [
              const Tab(text: 'Todas'),
              ..._phases.map((f) => Tab(text: f)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppLayout.pagePaddingAll,
                    child: Text(
                      'Nenhum jogo nesta fase.',
                      style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: AppLayout.pagePaddingHV,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final j = filtered[i];
                    return _JogoListCard(
                      jogo: j,
                      onTap: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _JogoListCard extends StatelessWidget {
  const _JogoListCard({required this.jogo, required this.onTap});

  final JogoDto jogo;
  final VoidCallback onTap;

  static bool _isFinished(JogoDto j) => j.status.toUpperCase() == 'FINISHED';
  static bool _isLive(JogoDto j) => j.status.toUpperCase() == 'IN_PROGRESS';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stadium = jogo.estadio?.trim();
    final finished = _isFinished(jogo);
    final live = _isLive(jogo);
    final gc = jogo.golsCasa;
    final gf = jogo.golsFora;

    Widget leftColumn() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatKickoffLongPtBr(jogo.kickoffAt),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (stadium != null && stadium.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              stadium,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    Widget centerColumn() {
      final nameStyle = textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      );
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        jogo.selecaoCasa.nome.toUpperCase(),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SelecaoFlagImage(
                      bandeiraUrl: jogo.selecaoCasa.bandeiraUrl,
                      width: 36,
                      height: 36,
                      shape: SelecaoFlagShape.circle,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (finished && gc != null && gf != null)
                      Text(
                        '$gc - $gf',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      )
                    else
                      Text(
                        '—',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      formatKickoffTimeOnly(jogo.kickoffAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SelecaoFlagImage(
                      bandeiraUrl: jogo.selecaoFora.bandeiraUrl,
                      width: 36,
                      height: 36,
                      shape: SelecaoFlagShape.circle,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        jogo.selecaoFora.nome.toUpperCase(),
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            jogo.fase,
            style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    Widget badge() {
      final label = formatJogoStatus(jogo.status);
      Color bg;
      Color fg;
      if (live) {
        bg = AppTheme.primary.withValues(alpha: 0.12);
        fg = AppTheme.primary;
      } else if (finished) {
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
      } else {
        bg = scheme.primaryContainer.withValues(alpha: 0.35);
        fg = scheme.onPrimaryContainer;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          finished ? 'FINAL' : label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: fg,
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            final pad = const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
            if (narrow) {
              return Padding(
                padding: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leftColumn(),
                    const SizedBox(height: 12),
                    centerColumn(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: badge(),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: pad,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 34, child: leftColumn()),
                  Expanded(flex: 46, child: centerColumn()),
                  Expanded(
                    flex: 20,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: badge(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
