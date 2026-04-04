import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/models/palpite_dto.dart';
import '../../../core/widgets/app_detail_skeleton.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/selecao_flag_image.dart';

/// Detalhe do jogo e registro do palpite.
class JogoDetailScreen extends StatefulWidget {
  const JogoDetailScreen({super.key, required this.jogoId, this.initialJogo});

  final String jogoId;
  final JogoDto? initialJogo;

  @override
  State<JogoDetailScreen> createState() => _JogoDetailScreenState();
}

class _JogoDetailScreenState extends State<JogoDetailScreen> {
  JogoDto? _jogo;
  bool _loadingJogo = true;
  String? _loadError;

  int? _palpiteId;

  final _casa = TextEditingController(text: '0');
  final _fora = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = int.tryParse(widget.jogoId);
    final initial = widget.initialJogo;
    if (initial != null && initial.id == id) {
      _jogo = initial;
      _loadingJogo = false;
      _loadPalpiteParaJogo(initial.id);
    } else if (id != null) {
      _fetchJogo(id);
    } else {
      _loadError = 'ID de jogo inválido';
      _loadingJogo = false;
    }
  }

  Future<void> _loadPalpiteParaJogo(int jogoId) async {
    try {
      final palpites = await BolaoApi.fetchMeusPalpites();
      PalpiteDto? mine;
      for (final p in palpites) {
        if (p.jogo.id == jogoId) {
          mine = p;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _palpiteId = mine?.id;
        _casa.text = '${mine?.golsCasaPalpite ?? 0}';
        _fora.text = '${mine?.golsForaPalpite ?? 0}';
      });
    } catch (_) {
      // Lista de palpites é opcional para exibir o formulário
    }
  }

  Future<void> _fetchJogo(int id) async {
    setState(() {
      _loadingJogo = true;
      _loadError = null;
    });
    try {
      final j = await BolaoApi.fetchJogoById(id);
      setState(() {
        _jogo = j;
        _loadingJogo = false;
      });
      await _loadPalpiteParaJogo(j.id);
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.statusCode == 404 ? 'Jogo não encontrado' : e.message;
        _loadingJogo = false;
      });
    } catch (e) {
      setState(() {
        _loadError = '$e';
        _loadingJogo = false;
      });
    }
  }

  @override
  void dispose() {
    _casa.dispose();
    _fora.dispose();
    super.dispose();
  }

  bool _podeEditarPalpite(JogoDto j) {
    if (j.status != 'SCHEDULED') return false;
    return DateTime.now().isBefore(j.kickoffAt);
  }

  Future<void> _salvarPalpite() async {
    final jogo = _jogo;
    if (jogo == null) return;
    final gc = int.tryParse(_casa.text.trim());
    final gf = int.tryParse(_fora.text.trim());
    if (gc == null || gf == null || gc < 0 || gf < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe gols válidos (≥ 0).')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final pid = _palpiteId;
      if (pid != null) {
        await BolaoApi.updatePalpite(palpiteId: pid, golsCasa: gc, golsFora: gf);
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Palpite atualizado.')),
        );
      } else {
        await BolaoApi.createPalpite(jogoId: jogo.id, golsCasa: gc, golsFora: gf);
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Palpite registrado.')),
        );
        await _loadPalpiteParaJogo(jogo.id);
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (context.mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingJogo) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jogos'),
          ),
          title: const Text('Carregando…'),
        ),
        body: const AppDetailSkeleton(),
      );
    }
    if (_loadError != null || _jogo == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jogos'),
          ),
          title: const Text('Jogo'),
        ),
        body: AppErrorView(
          title: 'Não foi possível abrir o jogo',
          message: _loadError ?? 'Jogo não encontrado',
          icon: Icons.sports_soccer_outlined,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          primaryLabel: 'Voltar para jogos',
          onPrimary: () => context.go('/jogos'),
        ),
      );
    }

    final j = _jogo!;
    final podePalpitar = _podeEditarPalpite(j);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/jogos'),
        ),
        title: Text(
          j.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      SelecaoFlagImage(bandeiraUrl: j.selecaoCasa.bandeiraUrl, width: 56, height: 40),
                      const SizedBox(height: 6),
                      Text(
                        j.selecaoCasa.nome,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'x',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Column(
                    children: [
                      SelecaoFlagImage(bandeiraUrl: j.selecaoFora.bandeiraUrl, width: 56, height: 40),
                      const SizedBox(height: 6),
                      Text(
                        j.selecaoFora.nome,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                j.titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${j.fase} · ${formatKickoff(j.kickoffAt)} · ${formatJogoStatus(j.status)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (j.golsCasa != null && j.golsFora != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Resultado: ${j.golsCasa} x ${j.golsFora}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 28),
              Text('Seu palpite', style: Theme.of(context).textTheme.titleMedium),
              if (!podePalpitar)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Não é possível alterar o palpite após o horário de início ou quando a partida não estiver agendada.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _casa,
                      enabled: podePalpitar && !_saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Gols ${j.selecaoCasa.nome}'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('x', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _fora,
                      enabled: podePalpitar && !_saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Gols ${j.selecaoFora.nome}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: (!podePalpitar || _saving) ? null : _salvarPalpite,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Salvando…'
                      : (_palpiteId != null ? 'Atualizar palpite' : 'Salvar palpite'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/jogos'),
                child: const Text('Voltar para jogos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
