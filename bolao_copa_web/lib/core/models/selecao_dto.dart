final class SelecaoDto {
  const SelecaoDto({
    required this.id,
    required this.nome,
    required this.bandeiraUrl,
    this.createdAt,
  });

  final int id;
  final String nome;
  final String bandeiraUrl;
  final DateTime? createdAt;

  factory SelecaoDto.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['bandeiraUrl'] ?? json['bandeira_url'];
    final url = rawUrl is String
        ? rawUrl
        : rawUrl == null
            ? ''
            : rawUrl.toString();
    return SelecaoDto(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      bandeiraUrl: url,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
