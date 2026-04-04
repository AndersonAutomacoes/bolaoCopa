import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/models/selecao_dto.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';

class AdminSelecoesScreen extends StatefulWidget {
  const AdminSelecoesScreen({super.key});

  @override
  State<AdminSelecoesScreen> createState() => _AdminSelecoesScreenState();
}

class _AdminSelecoesScreenState extends State<AdminSelecoesScreen> {
  late Future<List<SelecaoDto>> _future;

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Seleções (admin)'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _criarOuEditar(null),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<SelecaoDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar as seleções',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhuma seleção cadastrada',
              subtitle: 'Use o botão + para adicionar seleções e URLs de bandeira.',
              icon: Icons.flag_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = list[i];
              return ListTile(
                title: Text(s.nome),
                subtitle: Text(s.bandeiraUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _criarOuEditar(s)),
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _excluir(s)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
