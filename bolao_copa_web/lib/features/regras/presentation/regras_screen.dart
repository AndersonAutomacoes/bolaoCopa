import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Regras do bolão e dos planos (conteúdo estático alinhado ao domínio da API).
class RegrasScreen extends StatelessWidget {
  const RegrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Regras do bolão'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Copa do Mundo 2026',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const _Section(
            title: 'Pontuação dos palpites',
            body:
                'Após cada jogo finalizado, o sistema compara seu palpite com o resultado oficial.\n\n'
                '• Placar exato: 5 pontos.\n'
                '• Acertou apenas o vencedor (ou empate) do jogo: 3 pontos.\n'
                '• Errou o resultado: 0 pontos.\n\n'
                'O ranking geral usa o total de pontos. Em empate, desempata quem tiver mais acertos exatos; '
                'persistindo o empate, quem registrou o primeiro palpite mais cedo.',
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Prazo para palpitar',
            body:
                'Você pode criar ou alterar o palpite enquanto o jogo estiver agendado '
                'e antes do horário de início. Depois do apito inicial, o palpite fica travado.',
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Planos comerciais',
            body:
                'O plano (Bronze, Prata ou Ouro) define funcionalidades extras. Ele é independente do papel '
                'de administrador da plataforma (ROLE_ADMIN), usado apenas para gestão global.\n\n'
                '• Bronze: palpites, edição até o kickoff e ranking geral.\n'
                '• Prata: tudo do Bronze, mais bolões privados com convite por código e ranking dentro do bolão.\n'
                '• Ouro: tudo do Prata, mais módulo de premiação (regras e acompanhamento de pagamentos no escopo da API).',
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'Segurança',
            body:
                'O servidor valida plano e permissões em cada chamada. O aplicativo apenas oculta atalhos; '
                'não confie apenas na interface para acesso a dados sensíveis.',
          ),
          const SizedBox(height: 24),
          Text(
            'Dúvidas sobre o regulamento oficial da FIFA ou calendário de jogos devem ser consultadas nas fontes oficiais.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
