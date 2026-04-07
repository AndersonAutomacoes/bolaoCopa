import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/app_auth.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/models/palpite_dto.dart';
import '../../../core/models/ranking_item_dto.dart';
import '../../../core/models/user_profile_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;

/// Dados agregados para o dashboard (mockup: resumo + próximo jogo).
class _HomeData {
  _HomeData({
    required this.profile,
    required this.ranking,
    required this.jogos,
    required this.palpites,
  });

  final UserProfileDto profile;
  final List<RankingItemDto> ranking;
  final List<JogoDto> jogos;
  final List<PalpiteDto> palpites;

  RankingItemDto? get myRow {
    final e = profile.email.toLowerCase();
    for (final r in ranking) {
      if (r.email.toLowerCase() == e) return r;
    }
    return null;
  }

  JogoDto? get proximoJogoAgendado {
    final now = DateTime.now();
    final futuros = jogos.where((j) => j.status == 'SCHEDULED' && j.kickoffAt.isAfter(now)).toList()
      ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    return futuros.isEmpty ? null : futuros.first;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final results = await Future.wait([
      BolaoApi.fetchProfile(),
      BolaoApi.fetchRanking(),
      BolaoApi.fetchJogos(),
      BolaoApi.fetchMeusPalpites(),
    ]);
    final profile = results[0] as UserProfileDto;
    AppRouter.auth.syncPlanTierFromProfile(profile.planTier);
    return _HomeData(
      profile: profile,
      ranking: results[1] as List<RankingItemDto>,
      jogos: results[2] as List<JogoDto>,
      palpites: results[3] as List<PalpiteDto>,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppRouter.auth,
      builder: (context, _) {
        final auth = AppRouter.auth;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Início'),
            actions: AppShellAppBarActions.build(context),
          ),
          body: FutureBuilder<_HomeData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AppErrorView(
                  title: 'Não foi possível carregar o início',
                  message: apiErrorMessage(snapshot.error),
                  onPrimary: _reload,
                );
              }
              final data = snapshot.data!;
              final my = data.myRow;
              final wide = MediaQuery.sizeOf(context).width >= 1040;

              final leftColumn = _HomeLeftColumn(
                auth: auth,
                scheme: scheme,
                data: data,
              );

              final rightColumn = _HomeRightColumn(
                scheme: scheme,
                data: data,
                myRow: my,
              );

              if (!wide) {
                return SingleChildScrollView(
                  padding: AppLayout.pagePaddingHV,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftColumn,
                      const SizedBox(height: 20),
                      rightColumn,
                    ],
                  ),
                );
              }

              return Padding(
                padding: AppLayout.pagePaddingHV,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 62, child: leftColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 38, child: rightColumn),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeLeftColumn extends StatelessWidget {
  const _HomeLeftColumn({
    required this.auth,
    required this.scheme,
    required this.data,
  });

  final AppAuth auth;
  final ColorScheme scheme;
  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroBlock(scheme: scheme),
        const SizedBox(height: 20),
        _ActionRow(
          icon: Icons.sports_soccer,
          title: 'Jogos',
          subtitle: 'Veja a tabela e registre seu palpite antes do apito inicial.',
          ctaLabel: 'Ver jogos',
          onPressed: () => context.go(AppRoutes.jogos),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: Icons.leaderboard,
          title: 'Ranking',
          subtitle: 'Desempate: pontos, acertos exatos, data do primeiro palpite.',
          ctaLabel: 'Ver ranking',
          onPressed: () => context.go(AppRoutes.ranking),
        ),
        const SizedBox(height: 12),
        _ActionRow(
          icon: Icons.menu_book_outlined,
          title: 'Regras do bolão',
          subtitle: 'Pontuação, prazos e o que cada plano libera.',
          ctaLabel: 'Ler regras',
          onPressed: () => context.push(AppRoutes.regras),
        ),
        if (auth.tierPrataOrAbove) ...[
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.groups_outlined,
            title: 'Bolões privados',
            subtitle: 'Crie um bolão ou entre com o código de convite.',
            ctaLabel: 'Abrir',
            onPressed: () => context.push(AppRoutes.boloes),
          ),
        ],
        if (auth.tierOuro) ...[
          const SizedBox(height: 12),
          _ActionRow(
            icon: Icons.emoji_events_outlined,
            title: 'Premiação',
            subtitle: 'Regras e acompanhamento de premiação (Plano Ouro).',
            ctaLabel: 'Ver',
            onPressed: () => context.push(AppRoutes.premiacoes),
            accentGold: true,
          ),
        ],
      ],
    );
  }
}

class _HomeRightColumn extends StatelessWidget {
  const _HomeRightColumn({
    required this.scheme,
    required this.data,
    required this.myRow,
  });

  final ColorScheme scheme;
  final _HomeData data;
  final RankingItemDto? myRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResumoPontosCard(scheme: scheme, data: data, myRow: myRow),
        const SizedBox(height: 16),
        _ProximoJogoCard(scheme: scheme, jogo: data.proximoJogoAgendado),
      ],
    );
  }
}

class _ResumoPontosCard extends StatelessWidget {
  const _ResumoPontosCard({
    required this.scheme,
    required this.data,
    required this.myRow,
  });

  final ColorScheme scheme;
  final _HomeData data;
  final RankingItemDto? myRow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = myRow?.totalPontos ?? 0;
    final pos = myRow?.posicao;
    final totalParticipantes = data.ranking.length;
    final nPalpites = data.palpites.length;
    final acertos = myRow?.totalAcertosExatos ?? 0;
    final aproveitamento = nPalpites == 0 ? 0 : ((acertos / nPalpites) * 100).round().clamp(0, 100);

    return Card(
      child: Padding(
        padding: AppLayout.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumo dos seus pontos',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$total', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Total pontos', style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pos != null ? '#$posº' : '—',
                        style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        totalParticipantes > 0
                            ? 'Sua posição de $totalParticipantes'
                            : 'Ranking ainda vazio',
                        style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MiniStat(label: '$aproveitamento%', title: 'Aproveitamento'),
                _MiniStat(label: '$nPalpites', title: 'Palpites'),
                _MiniStat(label: '$acertos', title: 'Acertos exatos'),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.ranking),
              child: const Text('Ver detalhes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(title, style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ProximoJogoCard extends StatelessWidget {
  const _ProximoJogoCard({required this.scheme, required this.jogo});

  final ColorScheme scheme;
  final JogoDto? jogo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final j = jogo;
    return Card(
      child: Padding(
        padding: AppLayout.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Próximo jogo',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (j == null)
              Text(
                'Não há jogos agendados no futuro.',
                style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelecaoFlagImage(
                    bandeiraUrl: j.selecaoCasa.bandeiraUrl,
                    width: 36,
                    height: 36,
                    shape: SelecaoFlagShape.circle,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${j.selecaoCasa.nome.toUpperCase()}  vs  ${j.selecaoFora.nome.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SelecaoFlagImage(
                    bandeiraUrl: j.selecaoFora.bandeiraUrl,
                    width: 36,
                    height: 36,
                    shape: SelecaoFlagShape.circle,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${j.fase} · ${formatKickoff(j.kickoffAt)} · ${formatJogoStatus(j.status)}',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                child: const Text('Palpitar agora'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Copa do Mundo 2026',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua plataforma oficial do Bolão. Acompanhe jogos, faça palpites e dispute a liderança!',
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onPressed,
    this.accentGold = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onPressed;
  final bool accentGold;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = accentGold ? scheme.secondary : scheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 520;
          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ],
          );
          final button = FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(ctaLabel),
          );
          return Padding(
            padding: const EdgeInsets.all(18),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 36, color: iconColor),
                          const SizedBox(width: 14),
                          Expanded(child: textBlock),
                        ],
                      ),
                      const SizedBox(height: 14),
                      button,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, size: 36, color: iconColor),
                      const SizedBox(width: 14),
                      Expanded(child: textBlock),
                      const SizedBox(width: 12),
                      button,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
