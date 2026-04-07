final class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.idade,
    required this.sexo,
    required this.telefone,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.planTier = 'BRONZE',
    this.roles = 'ROLE_USER',
  });

  final int userId;
  final String email;
  final String fullName;
  final int idade;
  final String sexo;
  final String telefone;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String planTier;
  final String roles;

  bool get isAdmin => roles.contains('ADMIN');

  bool get isPrataOrAbove => planTier == 'PRATA' || planTier == 'OURO';

  bool get isOuro => planTier == 'OURO';

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      idade: (json['idade'] as num).toInt(),
      sexo: json['sexo'] as String,
      telefone: json['telefone'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      planTier: json['planTier'] as String? ?? 'BRONZE',
      roles: json['roles'] as String? ?? 'ROLE_USER',
    );
  }
}
