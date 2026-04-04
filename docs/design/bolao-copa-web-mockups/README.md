# Mockups de referência — Bolão Copa 2026 (web)

Este diretório concentra a **direção visual** (`DIRECAO_VISUAL_V1.md`) e os **PNG de referência** para implementação fidedigna no Flutter (`bolao_copa_web`).

## Onde versionar os PNG

| Local | Conteúdo |
|--------|-----------|
| [`reference/png/`](reference/png/) | Todos os ficheiros listados em [DIRECAO_VISUAL_V1.md](DIRECAO_VISUAL_V1.md) (nomes **exatos**; 24 ficheiros). |

Não renomeie os ficheiros: o código e a checklist assumem os nomes `mockup_*`, `state_*`, `mockup_dark_*`.

## Lista de ficheiros obrigatórios (24)

Copie os PNG gerados (Figma/export) para `reference/png/`:

**Claro — ecrãs principais**

- `mockup_01_splash.png` … `mockup_16_premiacoes.png` (ver tabela no `DIRECAO_VISUAL_V1.md`)

**Estados**

- `state_loading.png`, `state_error.png`, `state_empty.png`, `state_router_error.png`

**Escuro**

- `mockup_dark_01_inicio.png` … `mockup_dark_04_perfil.png`

## Git e ficheiros grandes

- **Repositório normal:** PNG até alguns MB por ficheiro costumam funcionar bem com Git puro.
- **Git LFS (opcional):** se o total dos mockups for grande ou o clone ficar pesado, instale [Git LFS](https://git-lfs.com/) e registe o padrão, por exemplo:

```bash
git lfs install
git lfs track "docs/design/**/*.png"
git add .gitattributes
```

Depois adicione os PNG normalmente. Quem clonar o repo precisa de `git lfs pull` (ou clone com LFS ativo) para obter os binários.

## Fluxo para a app ficar idêntica aos mockups

1. Garantir que os 24 PNG estão em `reference/png/`.
2. Seguir [CHECKLIST_IMPLEMENTACAO_MOCKUPS.md](CHECKLIST_IMPLEMENTACAO_MOCKUPS.md) e marcar cada item ao comparar **screenshot da app** com o PNG ao mesmo viewport (ex.: 1440×900 claro).
3. Ajustar primeiro `app_theme.dart` e widgets partilhados em `core/widgets/`, depois cada `*_screen.dart`.

## Relação com o código Flutter

- Tema: `bolao_copa_web/lib/core/theme/app_theme.dart`
- Checklist detalhada por ficheiro: [CHECKLIST_IMPLEMENTACAO_MOCKUPS.md](CHECKLIST_IMPLEMENTACAO_MOCKUPS.md)
