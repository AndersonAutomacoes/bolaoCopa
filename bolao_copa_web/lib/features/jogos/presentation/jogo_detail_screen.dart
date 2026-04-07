import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/bolao_api.dart';
import '../../../core/formatting/jogo_status_format.dart';
import '../../../core/formatting/kickoff_format.dart';
import '../../../core/models/jogo_dto.dart';
import '../../../core/models/palpite_dto.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_detail_skeleton.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_shell_app_bar_actions.dart';
import '../../../core/widgets/selecao_flag_image.dart' show SelecaoFlagImage, SelecaoFlagShape;

const int _kMaxPalpiteGols = 20;

/// Detalhe do jogo e registro do palpite (layout mockup: faixa meta, cartão VS, steppers).
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

  void _bump(TextEditingController c, int delta) {
    final v = int.tryParse(c.text.trim()) ?? 0;
    final n = (v + delta).clamp(0, _kMaxPalpiteGols);
    setState(() {
      c.text = '$n';
    });
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jogos'),
          ),
          title: const Text('Carregando…'),
          actions: AppShellAppBarActions.build(context),
        ),
        body: const AppDetailSkeleton(),
      );
    }
    if (_loadError != null || _jogo == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jogos'),
          ),
          title: const Text('Jogo'),
          actions: AppShellAppBarActions.build(context),
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

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stadium = j.estadio?.trim();
    final metaLine =
        'Copa do Mundo FIFA 2026 · ${j.fase} · ${formatKickoffMediumPtBr(j.kickoffAt)} · '
        '${stadium != null && stadium.isNotEmpty ? stadium : 'Local a definir'}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        actions: AppShellAppBarActions.build(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.editorialTextMaxWidth),
          child: ListView(
            padding: AppLayout.pagePaddingAll,
            children: [
              Text(
                metaLine,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cabeçalho do jogo',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: AppLayout.cardPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TeamVsBlock(
                              nome: j.selecaoCasa.nome,
                              bandeiraUrl: j.selecaoCasa.bandeiraUrl,
                              alignEnd: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VS',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatKickoffTimeOnly(j.kickoffAt),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _TeamVsBlock(
                              nome: j.selecaoFora.nome,
                              bandeiraUrl: j.selecaoFora.bandeiraUrl,
                              alignEnd: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      child: Row(
                        children: [
                          Icon(Icons.stadium_outlined, size: 18, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stadium != null && stadium.isNotEmpty
                                  ? '$stadium · Capacidade: —'
                                  : 'Estádio a definir',
                              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          Icon(Icons.wb_sunny_outlined, size: 18, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            '—',
                            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (j.golsCasa != null && j.golsFora != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Resultado oficial: ${j.golsCasa} × ${j.golsFora} · ${formatJogoStatus(j.status)}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'PALPITE (seu palpite)',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: AppLayout.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'SEU PALPITE',
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      if (!podePalpitar)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Não é possível alterar o palpite após o horário de início ou quando a partida não estiver agendada.',
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _GolStepper(
                              label: 'Gols ${j.selecaoCasa.nome.toUpperCase()}',
                              controller: _casa,
                              enabled: podePalpitar && !_saving,
                              onDecrement: () => _bump(_casa, -1),
                              onIncrement: () => _bump(_casa, 1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'X',
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Expanded(
                            child: _GolStepper(
                              label: 'Gols ${j.selecaoFora.nome.toUpperCase()}',
                              controller: _fora,
                              enabled: podePalpitar && !_saving,
                              onDecrement: () => _bump(_fora, -1),
                              onIncrement: () => _bump(_fora, 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Palpite válido até ${formatKickoffTimeOnly(j.kickoffAt)} (horário local do dispositivo).',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        'Pontuação estimada: conforme regras do bolão (ex.: placar exato, resultado ou empate).',
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: (!podePalpitar || _saving) ? null : _salvarPalpite,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        label: Text(_saving ? 'Salvando…' : 'Salvar palpite'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _saving ? null : () => context.go('/jogos'),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamVsBlock extends StatelessWidget {
  const _TeamVsBlock({
    required this.nome,
    required this.bandeiraUrl,
    required this.alignEnd,
  });

  final String nome;
  final String bandeiraUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final row = Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          SelecaoFlagImage(
            bandeiraUrl: bandeiraUrl,
            width: 48,
            height: 48,
            shape: SelecaoFlagShape.circle,
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            nome.toUpperCase(),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
              height: 1.2,
            ),
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: 10),
          SelecaoFlagImage(
            bandeiraUrl: bandeiraUrl,
            width: 48,
            height: 48,
            shape: SelecaoFlagShape.circle,
          ),
        ],
      ],
    );
    return row;
  }
}

class _GolStepper extends StatelessWidget {
  const _GolStepper({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final v = int.tryParse(controller.text.trim()) ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: enabled && v > 0 ? onDecrement : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$v',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: enabled && v < _kMaxPalpiteGols ? onIncrement : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}



