import 'dart:convert';

/// Erro retornado pela API Spring ([ApiErrorResponse]) ou falha de transporte.
final class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  String get message {
    if (body.isEmpty) {
      return 'Erro HTTP $statusCode';
    }
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final msg = map['message'] as String?;
      if (msg != null && msg.isNotEmpty) {
        return msg;
      }
      final fieldErrors = map['fieldErrors'] as Map<String, dynamic>?;
      if (fieldErrors != null && fieldErrors.isNotEmpty) {
        return fieldErrors.values.join('; ');
      }
    } catch (_) {
      // ignore
    }
    return body.length > 200 ? '${body.substring(0, 200)}…' : body;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
