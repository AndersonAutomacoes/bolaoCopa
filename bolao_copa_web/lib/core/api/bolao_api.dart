import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../models/jogo_dto.dart';
import '../models/palpite_dto.dart';
import '../models/ranking_item_dto.dart';
import '../models/user_profile_dto.dart';
import 'api_exception.dart';
import '../auth/session_tokens.dart';

/// Chamadas autenticadas à API `/api/v1`.
final class BolaoApi {
  BolaoApi._();

  static Uri _uri(String path) {
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  static Future<Map<String, String>> _jsonHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SessionTokens.accessTokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static void _throwIfError(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return;
    }
    throw ApiException(r.statusCode, r.body);
  }

  static Future<List<JogoDto>> fetchJogos() async {
    final r = await http.get(_uri(ApiConstants.jogosPath), headers: await _jsonHeaders());
    _throwIfError(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => JogoDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<JogoDto>> fetchJogosAndFind(int id) async {
    final all = await fetchJogos();
    return all.where((j) => j.id == id).toList();
  }

  static Future<void> createPalpite({
    required int jogoId,
    required int golsCasa,
    required int golsFora,
  }) async {
    final r = await http.post(
      _uri(ApiConstants.palpitesPath),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'jogoId': jogoId,
        'golsCasaPalpite': golsCasa,
        'golsForaPalpite': golsFora,
      }),
    );
    _throwIfError(r);
  }

  static Future<List<PalpiteDto>> fetchMeusPalpites() async {
    final r = await http.get(_uri('${ApiConstants.palpitesPath}/me'), headers: await _jsonHeaders());
    _throwIfError(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => PalpiteDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<RankingItemDto>> fetchRanking() async {
    final r = await http.get(_uri(ApiConstants.rankingPath), headers: await _jsonHeaders());
    _throwIfError(r);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => RankingItemDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<UserProfileDto> fetchProfile() async {
    final r = await http.get(_uri('${ApiConstants.usersPath}/me'), headers: await _jsonHeaders());
    _throwIfError(r);
    return UserProfileDto.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static Future<UserProfileDto> patchProfile({
    required String fullName,
    required int idade,
    required String sexo,
    required String telefone,
  }) async {
    final r = await http.patch(
      _uri('${ApiConstants.usersPath}/me'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'fullName': fullName,
        'idade': idade,
        'sexo': sexo,
        'telefone': telefone,
      }),
    );
    _throwIfError(r);
    return UserProfileDto.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }
}
