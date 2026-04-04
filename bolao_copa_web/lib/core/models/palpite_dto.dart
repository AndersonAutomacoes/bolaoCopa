import 'jogo_dto.dart';

final class PalpiteDto {
  const PalpiteDto({
    required this.id,
    required this.jogo,
    required this.golsCasaPalpite,
    required this.golsForaPalpite,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final JogoDto jogo;
  final int golsCasaPalpite;
  final int golsForaPalpite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PalpiteDto.fromJson(Map<String, dynamic> json) {
    return PalpiteDto(
      id: (json['id'] as num).toInt(),
      jogo: JogoDto.fromJson(json['jogo'] as Map<String, dynamic>),
      golsCasaPalpite: (json['golsCasaPalpite'] as num).toInt(),
      golsForaPalpite: (json['golsForaPalpite'] as num).toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}
