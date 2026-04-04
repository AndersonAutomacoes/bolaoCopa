# Direção visual v1 — Bolão Copa 2026 (bolao_copa_web)

**PNG gerados:** mesma pasta que este ficheiro — [`docs/design/bolao-copa-web-mockups/`](.) (24 ficheiros: `mockup_01`…`mockup_16`, `state_*`, `mockup_dark_*`). Cópias espelhadas podem existir em `.cursor/projects/.../assets/` no ambiente Cursor.

Consolidação de **três direções criativas** (equivalente a três análises com o subagente `layout-ui-visual-especialista`), fundidas num único sistema visual para implementação em Flutter (Material 3).

---

## Triângulo de propostas (resumo)

| Direção | Foco | Pontos fortes | Riscos |
|--------|------|----------------|--------|
| **A — Broadcast** | Estética de transmissão / placar eletrônico | Hierarquia forte, sensação “evento ao vivo” | Pode ficar escuro demais em listas longas |
| **B — Editorial** | Revista esportiva / ar | Legibilidade, respiro, confiança | Pode parecer “genérico SaaS” sem acento Copa |
| **C — Energia** | Torcida, dinamismo | Emoção de competição | Formas agressivas cansam em telas admin |

**Decisão fundida:** base **editorial clara (B)** para leitura e densidade de dados + **cabeçalhos e ranking com DNA de placar (A)** + **acento verde campo e ouro troféu (C moderado)** só onde há competição ou destaque — nunca em formulários densos.

---

## Tokens propostos (alvo)

### Claro (baseline)

- **Primary:** `#1B7F3A` (verde campo; CTAs, links fortes)
- **Secondary / accent gold:** `#C9A227` (medalhas, top 3, chips “Ouro/Prata”)
- **Surface page:** `#F1F5F9`
- **Surface card:** `#FFFFFF`
- **Text primary:** `#0F172A`
- **Text secondary:** `#64748B`
- **Outline / divider:** `#E2E8F0`
- **Seed M3 (alternativa):** manter harmonia com `ColorScheme.fromSeed` usando primary acima

### Escuro (dark)

- **Background:** `#0B1220`
- **Surface +1:** `#151D2E`
- **Surface +2 (elevated):** `#1E293B`
- **Primary (mesmo verde):** `#22C55E` ou `#4ADE80` para contraste em botões
- **Gold:** `#EAB308`
- **Text:** `#F8FAFC` / `#94A3B8` secundário

### Componentes

- **Cards:** canto 16px, sombra muito suave ou só borda `1px` em dark
- **App bar:** plano, título central; ações “Meus palpites” como texto+ícone discreto
- **Navigation rail (web ≥900px):** largura confortável, ícones outline / filled no selecionado
- **Estados:** skeleton em listas; erro com ícone, mensagem e “Tentar de novo”; vazio com ilustração leve + CTA

---

## Mapa de arquivos PNG (entrega)

| Arquivo | Conteúdo |
|---------|-----------|
| `mockup_01_splash.png` | Splash com logo bolão + Copa 2026 |
| `mockup_02_login.png` | Login em card central |
| `mockup_03_register.png` | Cadastro |
| `mockup_04_inicio.png` | Home com cards de fluxo |
| `mockup_05_jogos.png` | Lista de jogos |
| `mockup_06_jogo_detalhe.png` | Detalhe + palpite |
| `mockup_07_ranking.png` | Ranking global |
| `mockup_08_perfil.png` | Perfil do usuário |
| `mockup_09_meus_palpites.png` | Lista de palpites |
| `mockup_10_regras.png` | Texto regras |
| `mockup_11_admin_dashboard.png` | Admin home |
| `mockup_12_admin_selecoes.png` | CRUD seleções |
| `mockup_13_admin_jogos.png` | CRUD jogos |
| `mockup_14_boloes.png` | Bolões privados |
| `mockup_15_bolao_ranking.png` | Ranking de bolão |
| `mockup_16_premiacoes.png` | Premiação |
| `state_loading.png` | Skeleton lista jogos |
| `state_error.png` | Erro + Tentar de novo |
| `state_empty.png` | Lista vazia |
| `state_router_error.png` | Rota inválida |
| `mockup_dark_01_inicio.png` | Home dark |
| `mockup_dark_02_jogos.png` | Jogos dark |
| `mockup_dark_03_ranking.png` | Ranking dark |
| `mockup_dark_04_perfil.png` | Perfil dark |

---

## Próximos passos no código (referência)

- Estender [`bolao_copa_web/lib/core/theme/app_theme.dart`](../../../bolao_copa_web/lib/core/theme/app_theme.dart) com `ThemeData dark` e tokens acima.
- Opcional: `ThemeMode.system` no `MaterialApp` quando houver dark estável.
