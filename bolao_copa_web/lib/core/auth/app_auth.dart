import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_exception.dart';
import '../api/bolao_api.dart';
import '../constants/api_constants.dart';
import '../models/auth_response.dart';
import 'jwt_payload.dart';
import 'session_tokens.dart';

/// Sessão JWT com backend Spring (`/api/v1/auth/...`).
final class AppAuth extends ChangeNotifier {
  AppAuth();

  bool _initialized = false;
  bool _loggedIn = false;
  /// Plano comercial vindo do JWT (claim `planTier`) ou sincronizado com GET /users/me.
  String _planTier = 'BRONZE';

  bool get initialized => _initialized;
  bool get isLoggedIn => _loggedIn;

  /// Valor normalizado: BRONZE, PRATA ou OURO.
  String get planTier => _planTier;

  bool get tierPrataOrAbove => _planTier == 'PRATA' || _planTier == 'OURO';

  bool get tierOuro => _planTier == 'OURO';

  void _setPlanTier(String raw) {
    final t = raw.toUpperCase().trim();
    final next = t == 'PRATA' || t == 'OURO' || t == 'BRONZE' ? t : 'BRONZE';
    if (_planTier == next) return;
    _planTier = next;
    notifyListeners();
  }

  /// Após carregar o perfil, alinha o plano exibido nas rotas com o backend (ex.: upgrade manual pelo admin).
  void syncPlanTierFromProfile(String planTierFromApi) {
    _setPlanTier(planTierFromApi);
  }

  void _applyPlanTierFromAccessToken(String? token) {
    if (token == null || token.isEmpty) {
      _planTier = 'BRONZE';
      return;
    }
    final claims = decodeJwtPayload(token);
    _planTier = planTierFromJwtClaims(claims);
  }

  static const accessTokenKey = SessionTokens.accessTokenKey;
  static const refreshTokenKey = SessionTokens.refreshTokenKey;

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SessionTokens.accessTokenKey) ?? '';
      _loggedIn = token.isNotEmpty;
      _applyPlanTierFromAccessToken(token);
    } catch (_) {
      _loggedIn = false;
      _planTier = 'BRONZE';
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Uri _uri(String path) {
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Future<void> login(String email, String password) async {
    final trimmed = email.trim();
    final r = await http.post(
      _uri(ApiConstants.authLoginPath),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': trimmed, 'password': password}),
    );
    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, r.body);
    }
    final auth = AuthResponse.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    if (auth.mfaRequired) {
      throw ApiException(
        0,
        'Esta conta usa MFA. A verificação em duas etapas ainda não está disponível nesta versão web.',
      );
    }
    final access = auth.accessToken;
    final refresh = auth.refreshToken;
    if (access == null || access.isEmpty) {
      throw ApiException(0, 'Resposta de login sem access token.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionTokens.accessTokenKey, access);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(SessionTokens.refreshTokenKey, refresh);
    } else {
      await prefs.remove(SessionTokens.refreshTokenKey);
    }
    _loggedIn = true;
    _applyPlanTierFromAccessToken(access);
    notifyListeners();
  }

  /// Registro + login + perfil (`PATCH /api/v1/users/me`).
  Future<void> registerAndSetupProfile({
    required String email,
    required String password,
    required String fullName,
    required int idade,
    required String sexo,
    required String telefone,
  }) async {
    final trimmed = email.trim();
    final reg = await http.post(
      _uri(ApiConstants.authRegisterPath),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': trimmed, 'password': password}),
    );
    if (reg.statusCode != 201) {
      throw ApiException(reg.statusCode, reg.body);
    }
    await login(trimmed, password);
    await BolaoApi.patchProfile(
      fullName: fullName.trim(),
      idade: idade,
      sexo: sexo,
      telefone: telefone.trim(),
    );
  }

  /// Após redirect OAuth2 (tokens na query do [oauth-bridge]).
  Future<void> applyOAuthTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SessionTokens.accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(SessionTokens.refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(SessionTokens.refreshTokenKey);
    }
    _loggedIn = true;
    _applyPlanTierFromAccessToken(accessToken);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(SessionTokens.refreshTokenKey);
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await http.post(
          _uri(ApiConstants.authLogoutPath),
          headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'refreshToken': refresh}),
        );
      } catch (_) {
        // rede / token inválido: seguimos limpando sessão local
      }
    }
    await prefs.remove(SessionTokens.accessTokenKey);
    await prefs.remove(SessionTokens.refreshTokenKey);
    _loggedIn = false;
    _planTier = 'BRONZE';
    notifyListeners();
  }
}
