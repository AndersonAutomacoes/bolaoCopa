import 'dart:convert';

/// Decodifica o payload do JWT (sem verificar assinatura — apenas leitura de claims para UX).
/// A autorização real continua no servidor.
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  var payload = parts[1];
  final mod = payload.length % 4;
  if (mod > 0) {
    payload += '=' * (4 - mod);
  }
  payload = payload.replaceAll('-', '+').replaceAll('_', '/');
  try {
    final jsonStr = utf8.decode(base64Decode(payload));
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String planTierFromJwtClaims(Map<String, dynamic>? claims) {
  if (claims == null) return 'BRONZE';
  final raw = claims['planTier'];
  if (raw is! String || raw.isEmpty) return 'BRONZE';
  return raw.toUpperCase();
}
