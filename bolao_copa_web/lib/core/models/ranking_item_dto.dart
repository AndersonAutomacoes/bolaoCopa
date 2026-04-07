final class RankingItemDto {
  const RankingItemDto({
    required this.posicao,
    required this.userId,
    required this.email,
    this.nome,
    required this.totalPontos,
    required this.totalAcertosExatos,
    this.primeiroPalpiteEm,
    this.avatarUrl,
  });

  final int posicao;
  final int userId;
  final String email;
  final String? nome;
  final int totalPontos;
  final int totalAcertosExatos;
  final DateTime? primeiroPalpiteEm;
  final String? avatarUrl;

  factory RankingItemDto.fromJson(Map<String, dynamic> json) {
    return RankingItemDto(
      posicao: (json['posicao'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      nome: json['nome'] as String?,
      totalPontos: (json['totalPontos'] as num).toInt(),
      totalAcertosExatos: (json['totalAcertosExatos'] as num).toInt(),
      primeiroPalpiteEm:
          json['primeiroPalpiteEm'] != null ? DateTime.tryParse(json['primeiroPalpiteEm'] as String) : null,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
