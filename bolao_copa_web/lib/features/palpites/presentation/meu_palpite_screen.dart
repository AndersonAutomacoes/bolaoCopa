import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/palpite_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/notifications/in_app_notification_store.dart';
import '../../../core/widgets/branding_logo.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;

/// Lista consolidada dos palpites do usuário (mockup: cartões por jogo + navegação secundária).
class MeuPalpiteScreen extends StatefulWidget {
  const MeuPalpiteScreen({super.key});

  @override
  State<MeuPalpiteScreen> createState() => _MeuPalpiteScreenState();
}

class _MeuPalpiteScreenState extends State<MeuPalpiteScreen> {
  late Future<List<PalpiteDto>> _future;
  String _searchQuery = '';

  static const Color _appBarBg = Color(0xFF2C1810);
  static const Color _accentOrange = Color(0xFFC2410C);

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

  List<PalpiteDto> _filterPalpites(List<PalpiteDto> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      final j = p.jogo;
      return j.selecaoCasa.nome.toLowerCase().contains(q) ||
          j.selecaoFora.nome.toLowerCase().contains(q) ||
          j.fase.toLowerCase().contains(q) ||
          (j.rodada?.toLowerCase().contains(q) ?? false) ||
          '${j.id}'.contains(q);
    }).toList();
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrar palpites'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Time, fase ou nº do jogo',
            hintText: 'Ex.: Brasil, grupos…',
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Limpar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Aplicar')),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _searchQuery = result.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PalpitesWatermark(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: _appBarBg,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Voltar',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Meus palpites',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const BrandingLogo(height: 28),
                        Semantics(
                          label: 'Filtrar palpites por time ou jogo',
                          button: true,
                          child: IconButton(
                            tooltip: 'Filtrar por time ou jogo',
                            icon: Icon(
                              _searchQuery.isNotEmpty ? Icons.manage_search : Icons.search,
                              color: Colors.white,
                            ),
                            onPressed: _openSearch,
                          ),
                        ),
                        FutureBuilder<int>(
                          future: InAppNotificationStore.unreadCount(InAppNotificationIds.allDemo),
                          builder: (context, snap) {
                            final unread = snap.data ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  tooltip: 'Notificações',
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                  onPressed: () => context.push(AppRoutes.notificacoes),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<PalpiteDto>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
                    }
                    if (snapshot.hasError) {
                      return AppErrorView(
                        title: 'Não foi possível carregar seus palpites',
                        message: apiErrorMessage(snapshot.error),
                        onPrimary: _reload,
                      );
                    }
                    final raw = snapshot.data ?? [];
                    final list = _filterPalpites(raw);
                    if (raw.isEmpty) {
                      return AppEmptyState(
                        title: 'Você ainda não tem palpites registrados',
                        subtitle:
                            'Abra a lista de jogos e envie seus palpites antes do apito inicial.',
                        icon: Icons.edit_note_outlined,
                        actionLabel: 'Ver jogos e palpitar',
                        onAction: () => context.go(AppRoutes.jogos),
                      );
                    }
                    if (list.isEmpty) {
                      return AppEmptyState(
                        title: 'Nenhum palpite corresponde',
                        subtitle: _searchQuery.isEmpty
                            ? null
                            : 'Tente outro termo ou limpe o filtro (ícone de pesquisa).',
                        icon: Icons.search_off_outlined,
                        actionLabel: _searchQuery.isEmpty ? null : 'Limpar filtro',
                        onAction: _searchQuery.isEmpty
                            ? null
                            : () => setState(() => _searchQuery = ''),
                      );
                    }
                    return ListView.separated(
                      padding: AppLayout.pagePaddingHV,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final p = list[i];
                        final j = p.jogo;
                        final meta = StringBuffer(formatKickoffPalpiteMockup(j.kickoffAt));
                        if (j.rodada != null && j.rodada!.isNotEmpty) {
                          meta.write(' · ${j.rodada}');
                        }
                        meta.write(' · ${j.fase.toUpperCase()}');
                        return Card(
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  meta.toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          SelecaoFlagImage(
                                            bandeiraUrl: j.selecaoCasa.bandeiraUrl,
                                            width: 36,
                                            height: 36,
                                            shape: SelecaoFlagShape.circle,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              j.selecaoCasa.nome.toUpperCase(),
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        'vs.',
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              j.selecaoFora.nome.toUpperCase(),
                                              textAlign: TextAlign.end,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SelecaoFlagImage(
                                            bandeiraUrl: j.selecaoFora.bandeiraUrl,
                                            width: 36,
                                            height: 36,
                                            shape: SelecaoFlagShape.circle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _ScoreBox(
                                      value: '${p.golsCasaPalpite}',
                                      onEdit: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '×',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    _ScoreBox(
                                      value: '${p.golsForaPalpite}',
                                      onEdit: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Palpite · ${formatJogoStatus(j.status)}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _accentOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'SALVAR PALPITE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.value, required this.onEdit});

  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF5C4033), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PalpitesWatermark extends StatelessWidget {
  const _PalpitesWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.045,
              child: Icon(
                Icons.emoji_events,
                size: 320,
                color: Colors.brown.shade900,
              ),
            ),
          ),
          Center(
            child: Text(
              '26',
              style: TextStyle(
                fontSize: 200,
                fontWeight: FontWeight.w900,
                color: Colors.brown.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
