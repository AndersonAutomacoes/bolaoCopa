/// Nome amigável do plano comercial exibido na UI.
String formatPlanTierLabel(String tier) {
  switch (tier.toUpperCase()) {
    case 'BRONZE':
      return 'Bronze';
    case 'PRATA':
      return 'Prata';
    case 'OURO':
      return 'Ouro';
    default:
      return tier;
  }
}

/// Papel do usuário em linguagem de produto (sem nomes de roles técnicos).
String formatRolesLabel(String roles) {
  if (roles.toUpperCase().contains('ADMIN')) {
    return 'Administrador da plataforma';
  }
  return 'Participante';
}

/// Sexo para exibição em modo leitura (valores da API ou legados).
String formatSexoDisplay(String raw) {
  switch (raw.toUpperCase()) {
    case 'MASCULINO':
    case 'M':
    case 'MASC':
      return 'Masculino';
    case 'FEMININO':
    case 'F':
    case 'FEM':
      return 'Feminino';
    case 'OUTRO':
    case 'O':
      return 'Outro';
    case 'PREFIRO_NAO_INFORMAR':
      return 'Prefiro não informar';
    default:
      return raw;
  }
}
