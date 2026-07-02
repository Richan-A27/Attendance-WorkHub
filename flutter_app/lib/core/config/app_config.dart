class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue:
        'http://127.0.0.1:8080/api', // Use loopback address instead of localhost for better platform compat
  );
}
