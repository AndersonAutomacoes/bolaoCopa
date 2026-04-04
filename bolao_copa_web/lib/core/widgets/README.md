# Widgets de estado (`lib/core/widgets`)

Reutilizáveis para listas async e direção visual v1.

Importe os ficheiros necessários a partir de `lib/core/widgets/` (por exemplo `app_list_skeleton.dart`).

## `AppListSkeleton`

Use no ramo `waiting` de `FutureBuilder` quando o conteúdo for uma lista de cartões ou linhas semelhantes. Para ranking, use `AppListSkeleton.ranking()`.

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const AppListSkeleton(itemCount: 8);
}
```

## `AppErrorView`

Use quando `snapshot.hasError`. Mensagens: `apiErrorMessage(snapshot.error)` de `core/api/error_message.dart`.

```dart
if (snapshot.hasError) {
  return AppErrorView(
    title: 'Não foi possível carregar …',
    message: apiErrorMessage(snapshot.error),
    onPrimary: _reload,
  );
}
```

Botão primário: `onPrimary` (ou alias `onRetry`). Ícone e cor: `icon` / `iconColor`. Dois botões: `secondaryLabel` + `onSecondary`.

## `AppEmptyState`

Use quando `snapshot.hasData` e a lista está vazia (ou equivalente).

```dart
if (list.isEmpty) {
  return AppEmptyState(
    title: 'Nada por aqui',
    subtitle: 'Descrição opcional.',
    icon: Icons.inbox_outlined,
    actionLabel: 'Ação',
    onAction: () { … },
  );
}
```

## `AppDetailSkeleton`

Ecrã de detalhe (formulário / blocos) enquanto carrega.

## `BrandingLogo`, `RankingRankRow`, `RankingTableHeader`

- **BrandingLogo:** splash e cabeçalho do `NavigationRail`; asset `assets/branding/logo.png` (com fallback).
- **RankingTableHeader** + **RankingRankRow:** ranking com cabeçalho tipo tabela e destaque ouro no top 3.
