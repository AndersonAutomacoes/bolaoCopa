import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/models/selecao_dto.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';

class AdminJogosScreen extends StatefulWidget {
  const AdminJogosScreen({super.key});

  @override
  State<AdminJogosScreen> createState() => _AdminJogosScreenState();
}

class _AdminJogosScreenState extends State<AdminJogosScreen> {
  late Future<List<JogoDto>> _jogos;
  late Future<List<SelecaoDto>> _selecoes;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Jogos (admin)'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoJogo,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<JogoDto>>(
        future: _jogos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton();
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar os jogos',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhum jogo cadastrado',
              subtitle: 'Crie jogos após cadastrar pelo menos duas seleções.',
              icon: Icons.sports_soccer_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final j = list[i];
              return ListTile(
                title: Text(j.titulo),
                subtitle: Text('${j.fase} · ${formatKickoff(j.kickoffAt)} · ${formatJogoStatus(j.status)}'),
                trailing: j.status == 'SCHEDULED'
                    ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _excluir(j))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
