import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/selecao_dto.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;
import 'admin_shell_layout.dart';

class AdminSelecoesScreen extends StatefulWidget {
  const AdminSelecoesScreen({super.key});

  @override
  State<AdminSelecoesScreen> createState() => _AdminSelecoesScreenState();
}

class _AdminSelecoesScreenState extends State<AdminSelecoesScreen> {
  late Future<List<SelecaoDto>> _future;
  final Set<int> _selected = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchSelecoes();
    });
  }

  String _codigo(SelecaoDto s) {
    final n = s.nome.trim();
    if (n.length >= 3) return n.substring(0, 3).toUpperCase();
    return n.toUpperCase().padRight(3, 'X');
  }

  Future<void> _criarOuEditar([SelecaoDto? existing]) async {
    final nomeCtrl = TextEditingController(text: existing?.nome ?? '');
    final urlCtrl = TextEditingController(text: existing?.bandeiraUrl ?? '');
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nova seleção' : 'Editar seleção'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL bandeira')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      if (existing == null) {
        await BolaoApi.createSelecao(nome: nomeCtrl.text.trim(), bandeiraUrl: urlCtrl.text.trim());
      } else {
        await BolaoApi.patchSelecao(
          existing.id,
          nome: nomeCtrl.text.trim(),
          bandeiraUrl: urlCtrl.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo.')));
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _excluir(SelecaoDto s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir seleção?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await BolaoApi.deleteSelecao(s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluída.')));
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return AdminShellLayout(
      title: 'Seleções Nacionais',
      navIndex: 1,
      headerActions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
      child: FutureBuilder<List<SelecaoDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar as seleções',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          final filtered = _query.isEmpty
              ? list
              : list
                  .where(
                    (s) =>
                        s.nome.toLowerCase().contains(_query.toLowerCase()) ||
                        '${s.id}'.contains(_query) ||
                        _codigo(s).toLowerCase().contains(_query.toLowerCase()),
                  )
                  .toList();

          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhuma seleção cadastrada',
              subtitle: 'Use o botão + para adicionar seleções e URLs de bandeira.',
              icon: Icons.flag_outlined,
            );
          }

          return ListView(
            padding: AppLayout.pagePaddingHV,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seleções Nacionais',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _criarOuEditar(null),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    icon: const Icon(Icons.add, color: AppTheme.textPrimary),
                    label: const Text('+ Adicionar Nova Seleção'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar seleções (Nome, Código...)',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.inverseSurface,
                    ),
                    headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w700,
                        ),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columns: const [
                      DataColumn(label: Text('')),
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('CÓDIGO')),
                      DataColumn(label: Text('NOME DA SELEÇÃO')),
                      DataColumn(label: Text('SIGLA (FIFA)')),
                      DataColumn(label: Text('CONFEDERAÇÃO')),
                      DataColumn(label: Text('ÚLTIMA ATUALIZAÇÃO')),
                      DataColumn(label: Text('AÇÕES')),
                    ],
                    rows: filtered.asMap().entries.map((e) {
                      final s = e.value;
                      final idx = e.key;
                      final selected = _selected.contains(s.id);
                      final zebra = idx.isEven;
                      return DataRow(
                        selected: selected,
                        color: WidgetStateProperty.resolveWith((states) {
                          if (selected) return AppTheme.primary.withValues(alpha: 0.12);
                          return zebra
                              ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                              : null;
                        }),
                        cells: [
                          DataCell(
                            Checkbox(
                              value: selected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selected.add(s.id);
                                  } else {
                                    _selected.remove(s.id);
                                  }
                                });
                              },
                            ),
                          ),
                          DataCell(Text('${s.id}')),
                          DataCell(Text(_codigo(s))),
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
                          DataCell(Text(_codigo(s))),
                          const DataCell(Text('—')),
                          DataCell(Text(s.createdAt != null ? df.format(s.createdAt!.toLocal()) : '—')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _criarOuEditar(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _excluir(s),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Exibindo 1–${filtered.length} de ${list.length} itens',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
