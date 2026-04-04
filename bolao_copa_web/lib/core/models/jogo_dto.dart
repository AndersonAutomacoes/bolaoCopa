import 'selecao_dto.dart';

final class JogoDto {
  const JogoDto({
    required this.id,
    this.fifaMatchId,
    required this.fase,
    this.rodada,
    this.estadio,
    required this.kickoffAt,
    required this.status,
    this.golsCasa,
    this.golsFora,
    required this.selecaoCasa,
    required this.selecaoFora,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String? fifaMatchId;
  final String fase;
  final String? rodada;
  final String? estadio;
  final DateTime kickoffAt;
  final String status;
  final int? golsCasa;
  final int? golsFora;
  final SelecaoDto selecaoCasa;
  final SelecaoDto selecaoFora;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get titulo => '${selecaoCasa.nome} x ${selecaoFora.nome}';

  factory JogoDto.fromJson(Map<String, dynamic> json) {
    return JogoDto(
      id: (json['id'] as num).toInt(),
      fifaMatchId: json['fifaMatchId'] as String?,
      fase: json['fase'] as String,
      rodada: json['rodada'] as String?,
      estadio: json['estadio'] as String?,
      kickoffAt: DateTime.parse(json['kickoffAt'] as String),
      status: json['status'] as String,
      golsCasa: (json['golsCasa'] as num?)?.toInt(),
      golsFora: (json['golsFora'] as num?)?.toInt(),
      selecaoCasa: SelecaoDto.fromJson(json['selecaoCasa'] as Map<String, dynamic>),
      selecaoFora: SelecaoDto.fromJson(json['selecaoFora'] as Map<String, dynamic>),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}
