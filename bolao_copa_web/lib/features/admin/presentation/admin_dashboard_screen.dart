import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/models/selecao_dto.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;
import 'admin_shell_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<({List<SelecaoDto> selecoes, List<JogoDto> jogos})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({List<SelecaoDto> selecoes, List<JogoDto> jogos})> _load() async {
    final selecoes = await BolaoApi.fetchSelecoes();
    final jogos = await BolaoApi.fetchJogos();
    return (selecoes: selecoes, jogos: jogos);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      title: 'Painel de Controle',
      navIndex: 0,
      headerActions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
      child: FutureBuilder<({List<SelecaoDto> selecoes, List<JogoDto> jogos})>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar o painel',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final data = snapshot.data!;
          final selecoes = data.selecoes;
          final jogos = data.jogos;
          final agendados = jogos.where((j) => j.status == 'SCHEDULED').length;
          final pendentes = jogos.where((j) => j.status != 'FINISHED').length;

          final recentSelecoes = selecoes.take(4).toList();
          final proximosJogos = List<JogoDto>.from(jogos)
            ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
          final proximos = proximosJogos.take(3).toList();

          return SingleChildScrollView(
            padding: AppLayout.pagePaddingHV,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visão Geral',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _KpiCard(
                          icon: Icons.groups_2_outlined,
                          iconColor: const Color(0xFF2563EB),
                          label: 'Seleções ativas',
                          value: '${selecoes.length}',
                        ),
                        _KpiCard(
                          icon: Icons.calendar_month_outlined,
                          iconColor: const Color(0xFF2563EB),
                          label: 'Jogos agendados',
                          value: '$agendados',
                        ),
                        _KpiCard(
                          icon: Icons.emoji_events_outlined,
                          iconColor: const Color(0xFFCA8A04),
                          label: 'Resultados pendentes',
                          value: '$pendentes',
                        ),
                        const _KpiCard(
                          icon: Icons.notifications_outlined,
                          iconColor: Color(0xFF2563EB),
                          label: 'Notificações',
                          value: '15',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SelecoesRecentesCard(
                              selecoes: recentSelecoes,
                              onVerTudo: () => context.push(AppRoutes.adminSelecoes),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ProximosJogosCard(
                              jogos: proximos,
                              onVerTudo: () => context.push(AppRoutes.adminJogos),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _SelecoesRecentesCard(
                        selecoes: recentSelecoes,
                        onVerTudo: () => context.push(AppRoutes.adminSelecoes),
                      ),
                      const SizedBox(height: 16),
                      _ProximosJogosCard(
                        jogos: proximos,
                        onVerTudo: () => context.push(AppRoutes.adminJogos),
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelecoesRecentesCard extends StatelessWidget {
  const _SelecoesRecentesCard({
    required this.selecoes,
    required this.onVerTudo,
  });

  final List<SelecaoDto> selecoes;
  final VoidCallback onVerTudo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Seleções recentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(onPressed: onVerTudo, child: const Text('Ver tudo')),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('País')),
                  DataColumn(label: Text('Jogos')),
                  DataColumn(label: Text('Status')),
                ],
                rows: selecoes.isEmpty
                    ? [
                        const DataRow(
                          cells: [
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                          ],
                        ),
                      ]
                    : selecoes
                        .map(
                          (s) => DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    SelecaoFlagImage(
                                      bandeiraUrl: s.bandeiraUrl,
                                      width: 28,
                                      height: 28,
                                      shape: SelecaoFlagShape.circle,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(s.nome),
                                  ],
                                ),
                              ),
                              DataCell(Text(s.nome.length >= 2 ? s.nome.substring(0, 2).toUpperCase() : s.nome)),
                              const DataCell(Text('—')),
                              DataCell(
                                Chip(
                                  label: const Text('Ativo'),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelStyle: const TextStyle(fontSize: 11),
                                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProximosJogosCard extends StatelessWidget {
  const _ProximosJogosCard({
    required this.jogos,
    required this.onVerTudo,
  });

  final List<JogoDto> jogos;
  final VoidCallback onVerTudo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Próximos jogos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(onPressed: onVerTudo, child: const Text('Ver tudo')),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Horário')),
                  DataColumn(label: Text('Jogo')),
                  DataColumn(label: Text('Competição')),
                  DataColumn(label: Text('Local')),
                ],
                rows: jogos.isEmpty
                    ? [
                        const DataRow(
                          cells: [
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                            DataCell(Text('—')),
                          ],
                        ),
                      ]
                    : jogos
                        .map(
                          (j) => DataRow(
                            cells: [
                              DataCell(Text(formatKickoff(j.kickoffAt).split(' ').first)),
                              DataCell(Text(formatKickoff(j.kickoffAt).split(' ').last)),
                              DataCell(
                                Row(
                                  children: [
                                    SelecaoFlagImage(
                                      bandeiraUrl: j.selecaoCasa.bandeiraUrl,
                                      width: 22,
                                      height: 22,
                                      shape: SelecaoFlagShape.circle,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${j.selecaoCasa.nome} x ${j.selecaoFora.nome}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(j.fase)),
                              DataCell(Text(j.estadio ?? '—')),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
