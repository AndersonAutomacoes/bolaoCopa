import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/models/selecao_dto.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;
import 'admin_shell_layout.dart';

class AdminJogosScreen extends StatefulWidget {
  const AdminJogosScreen({super.key});

  @override
  State<AdminJogosScreen> createState() => _AdminJogosScreenState();
}

class _AdminJogosScreenState extends State<AdminJogosScreen> {
  late Future<List<JogoDto>> _jogos;
  late Future<List<SelecaoDto>> _selecoes;
  String _statusFilter = 'TODOS';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _jogos = BolaoApi.fetchJogos();
      _selecoes = BolaoApi.fetchSelecoes();
    });
  }

  Future<void> _novoJogo() async {
    final selecoes = await _selecoes;
    if (!mounted) return;
    if (selecoes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre pelo menos duas seleções antes.')),
      );
      return;
    }
    final faseCtrl = TextEditingController(text: 'Fase de grupos');
    SelecaoDto? casa = selecoes.first;
    SelecaoDto? fora = selecoes[1];
    DateTime kickoff = DateTime.now().add(const Duration(days: 1));

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Novo jogo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: faseCtrl, decoration: const InputDecoration(labelText: 'Fase')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SelecaoDto>(
                    decoration: const InputDecoration(labelText: 'Casa'),
                    initialValue: casa,
                    items: selecoes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                        .toList(),
                    onChanged: (v) => setD(() => casa = v),
                  ),
                  DropdownButtonFormField<SelecaoDto>(
                    decoration: const InputDecoration(labelText: 'Fora'),
                    initialValue: fora,
                    items: selecoes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                        .toList(),
                    onChanged: (v) => setD(() => fora = v),
                  ),
                  ListTile(
                    title: const Text('Data / hora do jogo'),
                    subtitle: Text(formatKickoff(kickoff)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        initialDate: kickoff,
                      );
                      if (d == null) return;
                      if (!ctx.mounted) return;
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(kickoff),
                      );
                      if (t == null) return;
                      setD(() {
                        kickoff = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Criar')),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted || casa == null || fora == null) return;
    final selCasa = casa!;
    final selFora = fora!;
    if (selCasa.id == selFora.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleções devem ser diferentes.')),
      );
      return;
    }
    try {
      await BolaoApi.createJogo(
        fase: faseCtrl.text.trim(),
        kickoffAt: kickoff.toUtc(),
        selecaoCasaId: selCasa.id,
        selecaoForaId: selFora.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jogo criado.')));
        _reload();
      }
    } catch (e) {
      if (e is ApiException && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _excluir(JogoDto j) async {
    if (j.status != 'SCHEDULED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Só é possível excluir jogos agendados sem palpites.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir jogo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await BolaoApi.deleteJogo(j.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído.')));
        _reload();
      }
    } catch (e) {
      if (e is ApiException && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editar(JogoDto j) async {
    if (j.status != 'SCHEDULED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Só é possível editar jogos agendados.')),
      );
      return;
    }
    final selecoes = await _selecoes;
    if (!mounted) return;
    final faseCtrl = TextEditingController(text: j.fase);
    final rodadaCtrl = TextEditingController(text: j.rodada ?? '');
    final estadioCtrl = TextEditingController(text: j.estadio ?? '');
    final fifaCtrl = TextEditingController(text: j.fifaMatchId ?? '');
    var casa = selecoes.firstWhere(
      (s) => s.id == j.selecaoCasa.id,
      orElse: () => j.selecaoCasa,
    );
    var fora = selecoes.firstWhere(
      (s) => s.id == j.selecaoFora.id,
      orElse: () => j.selecaoFora,
    );
    DateTime kickoff = j.kickoffAt;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Editar jogo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fifaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'FIFA match ID (opcional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: faseCtrl, decoration: const InputDecoration(labelText: 'Fase')),
                  const SizedBox(height: 8),
                  TextField(controller: rodadaCtrl, decoration: const InputDecoration(labelText: 'Rodada')),
                  const SizedBox(height: 8),
                  TextField(controller: estadioCtrl, decoration: const InputDecoration(labelText: 'Estádio')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SelecaoDto>(
                    decoration: const InputDecoration(labelText: 'Casa'),
                    initialValue: casa,
                    items: selecoes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setD(() => casa = v);
                    },
                  ),
                  DropdownButtonFormField<SelecaoDto>(
                    decoration: const InputDecoration(labelText: 'Fora'),
                    initialValue: fora,
                    items: selecoes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setD(() => fora = v);
                    },
                  ),
                  ListTile(
                    title: const Text('Data / hora do jogo'),
                    subtitle: Text(formatKickoff(kickoff)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        initialDate: kickoff,
                      );
                      if (d == null) return;
                      if (!ctx.mounted) return;
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(kickoff),
                      );
                      if (t == null) return;
                      setD(() {
                        kickoff = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    final selCasa = casa;
    final selFora = fora;
    if (selCasa.id == selFora.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleções devem ser diferentes.')),
      );
      return;
    }
    try {
      final patch = <String, dynamic>{
        'fase': faseCtrl.text.trim(),
        'kickoffAt': kickoff.toUtc().toIso8601String(),
        'selecaoCasaId': selCasa.id,
        'selecaoForaId': selFora.id,
      };
      final r = rodadaCtrl.text.trim();
      final e = estadioCtrl.text.trim();
      final f = fifaCtrl.text.trim();
      if (r.isNotEmpty) {
        patch['rodada'] = r;
      }
      if (e.isNotEmpty) {
        patch['estadio'] = e;
      }
      if (f.isNotEmpty) {
        patch['fifaMatchId'] = f;
      }
      await BolaoApi.patchJogo(j.id, patch);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jogo atualizado.')));
        _reload();
      }
    } catch (e) {
      if (e is ApiException && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return Colors.green;
      case 'SCHEDULED':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AdminShellLayout(
      title: 'Gerenciar Partidas',
      navIndex: 2,
      headerActions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
      child: FutureBuilder<List<JogoDto>>(
        future: _jogos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar os jogos',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          final filtered = list.where((j) {
            if (_statusFilter != 'TODOS' && j.status != _statusFilter) return false;
            if (_search.isEmpty) return true;
            final q = _search.toLowerCase();
            return j.selecaoCasa.nome.toLowerCase().contains(q) ||
                j.selecaoFora.nome.toLowerCase().contains(q) ||
                '${j.id}'.contains(q);
          }).toList();

          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhum jogo cadastrado',
              subtitle: 'Crie jogos após cadastrar pelo menos duas seleções.',
              icon: Icons.sports_soccer_outlined,
            );
          }

          final mq = MediaQuery.sizeOf(context);
          final tableMinWidth = math.max(1080.0, mq.width - 40);

          return Padding(
            padding: AppLayout.pagePaddingHV,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gerenciar Partidas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _novoJogo,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('+ Nova Partida'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TODOS', child: Text('Todos os Status')),
                          DropdownMenuItem(value: 'SCHEDULED', child: Text('Agendado')),
                          DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Em andamento')),
                          DropdownMenuItem(value: 'FINISHED', child: Text('Finalizado')),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v ?? 'TODOS'),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: const InputDecoration(
                          labelText: 'Buscar por time',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Scrollbar(
                          notificationPredicate: (ScrollNotification n) =>
                              n.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: tableMinWidth),
                              child: DataTable(
                    headingRowColor: WidgetStateProperty.all(scheme.surfaceContainerHighest),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 56,
                    columns: const [
                      DataColumn(label: Text('ID #')),
                      DataColumn(label: Text('Data/Hora')),
                      DataColumn(label: Text('Fase')),
                      DataColumn(label: Text('Rodada')),
                      DataColumn(label: Text('Mandante')),
                      DataColumn(label: Text('Placar')),
                      DataColumn(label: Text('Visitante')),
                      DataColumn(label: Text('Estádio')),
                      DataColumn(label: Text('FIFA ID')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Ações')),
                    ],
                    rows: filtered.asMap().entries.map((e) {
                      final j = e.value;
                      final idx = e.key;
                      final placar = j.golsCasa != null && j.golsFora != null
                          ? '${j.golsCasa} - ${j.golsFora}'
                          : 'vs';
                      final zebra = idx.isEven;
                      return DataRow(
                        color: WidgetStateProperty.resolveWith((_) {
                          return zebra
                              ? scheme.surfaceContainerHighest.withValues(alpha: 0.25)
                              : null;
                        }),
                        cells: [
                          DataCell(Text('${j.id}')),
                          DataCell(Text(formatKickoff(j.kickoffAt))),
                          DataCell(Text(j.fase)),
                          DataCell(Text(j.rodada?.isNotEmpty == true ? j.rodada! : '—')),
                          DataCell(
                            Row(
                              children: [
                                SelecaoFlagImage(
                                  key: ValueKey('jogo-${j.id}-casa-${j.selecaoCasa.bandeiraUrl}'),
                                  bandeiraUrl: j.selecaoCasa.bandeiraUrl,
                                  width: 22,
                                  height: 22,
                                  shape: SelecaoFlagShape.circle,
                                ),
                                const SizedBox(width: 6),
                                Text(j.selecaoCasa.nome),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              placar,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                SelecaoFlagImage(
                                  key: ValueKey('jogo-${j.id}-fora-${j.selecaoFora.bandeiraUrl}'),
                                  bandeiraUrl: j.selecaoFora.bandeiraUrl,
                                  width: 22,
                                  height: 22,
                                  shape: SelecaoFlagShape.circle,
                                ),
                                const SizedBox(width: 6),
                                Text(j.selecaoFora.nome),
                              ],
                            ),
                          ),
                          DataCell(Text(j.estadio ?? '—')),
                          DataCell(Text(j.fifaMatchId ?? '—')),
                          DataCell(
                            Chip(
                              label: Text(formatJogoStatus(j.status)),
                              backgroundColor: _statusColor(j.status).withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: _statusColor(j.status).withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  label: 'Ver detalhes do jogo ${j.id}',
                                  button: true,
                                  child: IconButton(
                                    tooltip: 'Ver jogo',
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    onPressed: () => context.push('${AppRoutes.jogos}/${j.id}', extra: j),
                                  ),
                                ),
                                Semantics(
                                  label: 'Editar jogo ${j.id}',
                                  button: true,
                                  child: IconButton(
                                    tooltip: 'Editar',
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: j.status == 'SCHEDULED' ? () => _editar(j) : null,
                                  ),
                                ),
                                Semantics(
                                  label: 'Excluir jogo ${j.id}',
                                  button: true,
                                  child: IconButton(
                                    tooltip: 'Excluir',
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: j.status == 'SCHEDULED' ? () => _excluir(j) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Exibindo 1–${filtered.length} de ${list.length} partidas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
