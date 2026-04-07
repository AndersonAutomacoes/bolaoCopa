import 'package:shared_preferences/shared_preferences.dart';

/// IDs das notificações in-app (MVP sem backend).
abstract final class InAppNotificationIds {
  static const palpiteFechado = 'palpite_fechado';
  static const jogoResultado = 'jogo_resultado';
  static const rankingAtualizado = 'ranking_atualizado';
  static const bolaoConvite = 'bolao_convite';

  /// Lista fixa usada pelo centro de notificações in-app (MVP).
  static const List<String> allDemo = [
    palpiteFechado,
    jogoResultado,
    rankingAtualizado,
    bolaoConvite,
  ];
}

/// Persistência simples de «lidas» para o centro de notificações.
final class InAppNotificationStore {
  InAppNotificationStore._();

  static const _key = 'in_app_notifications_read';

  static Future<Set<String>> readIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  static Future<void> markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await readIds();
    set.add(id);
    await prefs.setString(_key, set.join(','));
  }

  static Future<void> markAllRead(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await readIds();
    set.addAll(ids);
    await prefs.setString(_key, set.join(','));
  }

  static Future<int> unreadCount(Iterable<String> allIds) async {
    final read = await readIds();
    return allIds.where((id) => !read.contains(id)).length;
  }
}
