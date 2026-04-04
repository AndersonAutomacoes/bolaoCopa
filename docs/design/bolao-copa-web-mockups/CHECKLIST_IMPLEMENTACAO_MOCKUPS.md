# Checklist — implementação fidedigna aos mockups

**Referência visual:** PNG em [`reference/png/`](reference/png/) + tokens em [`DIRECAO_VISUAL_V1.md`](DIRECAO_VISUAL_V1.md).

**Como usar:** para cada linha, comparar o ecrã em Flutter com o PNG indicado (mesma largura de janela quando possível). Marcar `[ ]` → `[x]` quando o layout, espaçamentos, hierarquia tipográfica e cores coincidirem com o mockup.

**Ordem sugerida:** `app_theme.dart` → widgets `core/widgets/` partilhados → `main_scaffold.dart` → restantes por ordem da tabela.

---

## Globais (afetam todos os ecrãs)

| Ficheiro | Mockup / notas | O que ajustar |
|----------|----------------|----------------|
| [`bolao_copa_web/lib/core/theme/app_theme.dart`](../../../bolao_copa_web/lib/core/theme/app_theme.dart) | Todos | `ColorScheme`, `TextTheme` (pesos/entrelinhas), `CardTheme` (16px), `AppBarTheme` (plano, título central), `InputDecorationTheme`, `FilledButtonTheme`, `DividerTheme`, `NavigationBarTheme`, `NavigationRailTheme`; validar dark vs `mockup_dark_*` |
| [`bolao_copa_web/lib/app.dart`](../../../bolao_copa_web/lib/app.dart) | — | `theme` / `darkTheme` / `themeMode` alinhados aos testes em claro e escuro |
| [`bolao_copa_web/lib/core/widgets/branding_logo.dart`](../../../bolao_copa_web/lib/core/widgets/branding_logo.dart) | `mockup_01`, `mockup_04`, rail | Tamanhos, padding, asset `logo.png` vs mockup |

---

## Shell e navegação

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/shell/presentation/main_scaffold.dart`](../../../bolao_copa_web/lib/features/shell/presentation/main_scaffold.dart) | `mockup_04` (contexto rail), `mockup_dark_01` | `NavigationRail`: `extended`, `minExtendedWidth`, `leading` (logo + títulos “Bolão” / “Copa 2026”), `destinations` outline/filled, `indicatorColor`; `Scaffold` + branch content; versão mobile: `NavigationBar` + mesma hierarquia visual |

---

## Autenticação e arranque

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/splash/presentation/splash_screen.dart`](../../../bolao_copa_web/lib/features/splash/presentation/splash_screen.dart) | `mockup_01_splash.png` | `Scaffold` fundo, `BrandingLogo` altura, título “Bolão Copa 2026”, `CircularProgressIndicator` (tamanho/cor), espaçamentos verticais |
| [`bolao_copa_web/lib/features/auth/presentation/login_screen.dart`](../../../bolao_copa_web/lib/features/auth/presentation/login_screen.dart) | `mockup_02_login.png` | Centragem do card, largura máxima do formulário, campos e-mail/senha, botão primário, link “Cadastrar”, espaçamento interno do card |
| [`bolao_copa_web/lib/features/auth/presentation/register_screen.dart`](../../../bolao_copa_web/lib/features/auth/presentation/register_screen.dart) | `mockup_03_register.png` | Mesma estrutura que login: card, campos adicionais, validação visual, CTA, link voltar/login |

---

## Início e fluxos principais

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/home/presentation/home_screen.dart`](../../../bolao_copa_web/lib/features/home/presentation/home_screen.dart) | `mockup_04_inicio.png`, `mockup_dark_01_inicio.png` | `AppBar` título + `TextButton.icon` “Meus palpites”; `ColoredBox`/`ListView` padding; `_HeroBlock`; `_FlowCard` (ícone, título, subtítulo, ripple); card “Pontuação”; secções condicionais Bolões/Premiação |

---

## Jogos

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/jogos/presentation/jogos_list_screen.dart`](../../../bolao_copa_web/lib/features/jogos/presentation/jogos_list_screen.dart) | `mockup_05_jogos.png`, `mockup_dark_02_jogos.png` | `AppBar`; lista: cartões/linhas, datas, seleções, estados; alinhar com [`app_list_skeleton.dart`](../../../bolao_copa_web/lib/core/widgets/app_list_skeleton.dart) e [`app_empty_state.dart`](../../../bolao_copa_web/lib/core/widgets/app_empty_state.dart) para `state_loading` / `state_empty` |
| [`bolao_copa_web/lib/features/jogos/presentation/jogo_detail_screen.dart`](../../../bolao_copa_web/lib/features/jogos/presentation/jogo_detail_screen.dart) | `mockup_06_jogo_detalhe.png` | Cabeçalho do jogo, bandeiras ([`selecao_flag_image.dart`](../../../bolao_copa_web/lib/core/widgets/selecao_flag_image.dart)), formulário de palpite, botões, prazo; skeleton: [`app_detail_skeleton.dart`](../../../bolao_copa_web/lib/core/widgets/app_detail_skeleton.dart) |

---

## Ranking e palpites

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/ranking/presentation/ranking_screen.dart`](../../../bolao_copa_web/lib/features/ranking/presentation/ranking_screen.dart) | `mockup_07_ranking.png`, `mockup_dark_03_ranking.png` | Cabeçalho estilo “placar”; tabela/lista; [`ranking_table_header.dart`](../../../bolao_copa_web/lib/core/widgets/ranking_table_header.dart); [`ranking_rank_row.dart`](../../../bolao_copa_web/lib/core/widgets/ranking_rank_row.dart) (top 3, ouro `#C9A227` moderado) |
| [`bolao_copa_web/lib/features/palpites/presentation/meu_palpite_screen.dart`](../../../bolao_copa_web/lib/features/palpites/presentation/meu_palpite_screen.dart) | `mockup_09_meus_palpites.png` | `AppBar`; lista de palpites por jogo; cartões ou linhas; estados vazio/erro |

---

## Perfil e conteúdo estático

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/perfil/presentation/perfil_screen.dart`](../../../bolao_copa_web/lib/features/perfil/presentation/perfil_screen.dart) | `mockup_08_perfil.png`, `mockup_dark_04_perfil.png` | Avatar, dados do utilizador, plano, ações, espaçamento editorial |
| [`bolao_copa_web/lib/features/regras/presentation/regras_screen.dart`](../../../bolao_copa_web/lib/features/regras/presentation/regras_screen.dart) | `mockup_10_regras.png` | `AppBar`; corpo texto longo: margens, `TextStyle` por parágrafo/título, listas |

---

## Admin

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/admin/presentation/admin_dashboard_screen.dart`](../../../bolao_copa_web/lib/features/admin/presentation/admin_dashboard_screen.dart) | `mockup_11_admin_dashboard.png` | Grid/lista de entradas admin, cards mais neutros (menos acento “energia”) |
| [`bolao_copa_web/lib/features/admin/presentation/admin_selecoes_screen.dart`](../../../bolao_copa_web/lib/features/admin/presentation/admin_selecoes_screen.dart) | `mockup_12_admin_selecoes.png` | Tabela/form CRUD, cabeçalhos, botões de ação |
| [`bolao_copa_web/lib/features/admin/presentation/admin_jogos_screen.dart`](../../../bolao_copa_web/lib/features/admin/presentation/admin_jogos_screen.dart) | `mockup_13_admin_jogos.png` | Idem, densidade de dados, alinhamentos |

---

## Bolões e premiação

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/features/bolao_grupo/presentation/bolao_grupos_screen.dart`](../../../bolao_copa_web/lib/features/bolao_grupo/presentation/bolao_grupos_screen.dart) | `mockup_14_boloes.png`, `mockup_15_bolao_ranking.png` | `BolaoGruposScreen`: lista de bolões, CTAs, chips; `BolaoRankingScreen`: ranking dentro do bolão (paridade com ranking global + mockup 15) |
| [`bolao_copa_web/lib/features/premiacao/presentation/premiacao_screen.dart`](../../../bolao_copa_web/lib/features/premiacao/presentation/premiacao_screen.dart) | `mockup_16_premiacoes.png` | Secções de premiação, hierarquia com ouro troféu só onde o mockup destacar |

---

## Erros, estados e router

| Ficheiro | Mockup | Widgets / áreas a ajustar |
|----------|--------|---------------------------|
| [`bolao_copa_web/lib/core/widgets/app_list_skeleton.dart`](../../../bolao_copa_web/lib/core/widgets/app_list_skeleton.dart) | `state_loading.png` | Número de linhas, alturas, cantos, cor de placeholder |
| [`bolao_copa_web/lib/core/widgets/app_detail_skeleton.dart`](../../../bolao_copa_web/lib/core/widgets/app_detail_skeleton.dart) | `state_loading.png` (detalhe) | Layout do skeleton alinhado ao detalhe de jogo |
| [`bolao_copa_web/lib/core/widgets/app_error_view.dart`](../../../bolao_copa_web/lib/core/widgets/app_error_view.dart) | `state_error.png` | Ícone, mensagem, botão “Tentar de novo”, padding |
| [`bolao_copa_web/lib/core/widgets/app_empty_state.dart`](../../../bolao_copa_web/lib/core/widgets/app_empty_state.dart) | `state_empty.png` | Ilustração/ícone leve, copy, CTA primário |
| [`bolao_copa_web/lib/core/router/router_error_screen.dart`](../../../bolao_copa_web/lib/core/router/router_error_screen.dart) | `state_router_error.png` | Mensagem de rota inválida, ação para voltar/início |

---

## Router (apenas referência)

| Ficheiro | Notas |
|----------|--------|
| [`bolao_copa_web/lib/core/router/app_router.dart`](../../../bolao_copa_web/lib/core/router/app_router.dart) | Não é UI; garantir que cada `path` corresponde ao ecrã certo na checklist acima. |

---

## Critério de conclusão

- [ ] Os 24 PNG estão em `reference/png/` com nomes corretos.
- [ ] Todas as linhas desta checklist estão marcadas para claro **e**, onde aplicável, validadas em dark com `mockup_dark_*`.
- [ ] Não há cores hex soltas fora de `AppTheme` / `Theme.of(context).colorScheme` (exceto acentos pontuais já documentados na direção visual).
