/// Base URL da API Spring Boot (ajuste por ambiente).
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String apiV1 = '/api/v1';

  static const String authRegisterPath = '$apiV1/auth/register';
  static const String authLoginPath = '$apiV1/auth/login';
  static const String authLogoutPath = '$apiV1/auth/logout';

  static const String usersPath = '$apiV1/users';
  static const String jogosPath = '$apiV1/jogos';
  static const String selecoesPath = '$apiV1/selecoes';
  static const String palpitesPath = '$apiV1/palpites';
  static const String rankingPath = '$apiV1/ranking';
  static const String boloesPath = '$apiV1/boloes';
  static const String premiacoesPath = '$apiV1/premiacoes';
}
