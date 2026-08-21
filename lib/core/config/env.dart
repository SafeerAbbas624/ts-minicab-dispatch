/// Build-time configuration. Override with:
/// flutter run --dart-define=API_BASE_URL=https://api.tsminicab.com
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.tsminicab.com',
  );
}
