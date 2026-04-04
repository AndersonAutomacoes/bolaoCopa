import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';

/// Detalhe do jogo + POST /api/v1/palpites.
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
    } else if (id != null) {
      _fetchJogo(id);
    } else {
      _loadError = 'ID de jogo inválido';
      _loadingJogo = false;
    }
  }

  Future<void> _fetchJogo(int id) async {
    setState(() {
      _loadingJogo = true;
      _loadError = null;
    });
    try {
      final found = await BolaoApi.fetchJogosAndFind(id);
      if (found.isEmpty) {
        setState(() {
          _jogo = null;
          _loadError = 'Jogo não encontrado';
          _loadingJogo = false;
        });
        return;
      }
      setState(() {
        _jogo = found.first;
        _loadingJogo = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e is ApiException ? e.message : '$e';
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
      await BolaoApi.createPalpite(jogoId: jogo.id, golsCasa: gc, golsFora: gf);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Palpite registrado na API.')),
      );
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
          title: const Text('Jogo'),
        ),
        body: const Center(child: CircularProgressIndicator()),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError ?? 'Jogo não encontrado', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/jogos'),
                  child: const Text('Voltar para jogos'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final j = _jogo!;
    final podePalpitar = j.status == 'SCHEDULED';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/jogos'),
        ),
        title: Text('Jogo #${j.id}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                j.titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${j.fase} · ${formatKickoff(j.kickoffAt)} · ${j.status}',
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
                    'Este jogo não aceita novos palpites (status ${j.status}).',
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
                label: Text(_saving ? 'Salvando…' : 'Salvar palpite'),
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
