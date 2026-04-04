/// Formata centavos (inteiro) como moeda brasileira legível na UI.
String formatBrlFromCentavos(int centavos) {
  final reais = centavos / 100.0;
  final s = reais.abs().toStringAsFixed(2);
  final prefix = centavos < 0 ? '- ' : '';
  return '${prefix}R\$ ${s.replaceFirst('.', ',')}';
}
