import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/api/error_message.dart';
import '../../../core/formatting/currency_format.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_list_skeleton.dart';

class PremiacaoScreen extends StatefulWidget {
  const PremiacaoScreen({super.key});

  @override
  State<PremiacaoScreen> createState() => _PremiacaoScreenState();
}

class _PremiacaoScreenState extends State<PremiacaoScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = BolaoApi.fetchPremiacoesRegrasMine();
    });
  }

  Future<void> _novaRegra() async {
    final nomeCtrl = TextEditingController(text: 'Premiação campeonato');
    var escopo = 'CAMPEONATO';
    final qtdCtrl = TextEditingController(text: '3');
    final valorCtrl = TextEditingController(text: '50000');

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Nova regra (Plano Ouro)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Escopo'),
                    initialValue: escopo,
                    items: const [
                      DropdownMenuItem(value: 'CAMPEONATO', child: Text('Campeonato')),
                      DropdownMenuItem(value: 'JOGO', child: Text('Jogo')),
                    ],
                    onChanged: (v) => setD(() => escopo = v ?? escopo),
                  ),
                  TextField(
                    controller: qtdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qtd premiados'),
                  ),
                  TextField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor total (centavos)',
                      helperText: 'Ex.: 50000 = R\$ 500,00',
                    ),
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
    if (ok != true || !mounted) return;
    final qtd = int.tryParse(qtdCtrl.text.trim());
    final valor = int.tryParse(valorCtrl.text.trim());
    if (qtd == null || valor == null) return;
    try {
      await BolaoApi.createPremiacaoRegra(
        nome: nomeCtrl.text.trim(),
        escopo: escopo,
        qtdPremiados: qtd,
        valorTotalCentavos: valor,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regra criada.')));
        _reload();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Premiação'),
        actions: AppShellAppBarActions.build(
          context,
          extra: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _novaRegra,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppListSkeleton(padding: AppLayout.pagePaddingAll);
          }
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Não foi possível carregar a premiação',
              message: apiErrorMessage(snapshot.error),
              onPrimary: _reload,
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const AppEmptyState(
              title: 'Nenhuma regra cadastrada',
              subtitle: 'Crie uma regra de premiação para o plano Ouro.',
              icon: Icons.emoji_events_outlined,
            );
          }
          final scheme = Theme.of(context).colorScheme;
          return ListView.separated(
            padding: AppLayout.pagePaddingHV,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = list[i];
              final rawCent = r['valorTotalCentavos'];
              final centavos = rawCent is int
                  ? rawCent
                  : (rawCent is num ? rawCent.toInt() : int.tryParse('$rawCent') ?? 0);
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryGold.withValues(alpha: 0.22),
                    child: Icon(Icons.emoji_events_outlined, size: 22, color: scheme.secondary),
                  ),
                  title: Text(
                    r['nome'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Escopo: ${r['escopo']} · Premiados: ${r['qtdPremiados']} · Total: ${formatBrlFromCentavos(centavos)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
