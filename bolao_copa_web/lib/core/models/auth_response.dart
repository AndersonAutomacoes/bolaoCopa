final class AuthResponse {
  const AuthResponse({
    required this.mfaRequired,
    this.accessToken,
    this.challengeToken,
    this.refreshToken,
  });

  final bool mfaRequired;
  final String? accessToken;
  final String? challengeToken;
  final String? refreshToken;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      mfaRequired: json['mfaRequired'] as bool? ?? false,
      accessToken: json['accessToken'] as String?,
      challengeToken: json['challengeToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}
