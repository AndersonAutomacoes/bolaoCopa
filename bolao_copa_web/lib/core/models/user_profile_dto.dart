final class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.idade,
    required this.sexo,
    required this.telefone,
    this.createdAt,
    this.updatedAt,
  });

  final int userId;
  final String email;
  final String fullName;
  final int idade;
  final String sexo;
  final String telefone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      idade: (json['idade'] as num).toInt(),
      sexo: json['sexo'] as String,
      telefone: json['telefone'] as String,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}
