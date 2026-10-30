/// Build-time configuration. Override with:
/// flutter run --dart-define=API_BASE_URL=https://api.tsminicab.com
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.tsminicab.com',
  );

  /// Where the passenger's private tracking / manage-booking page lives
  /// (`tsminicab.com/track/<token>`) — staging builds point at the staging site.
  static const String trackingBaseUrl = String.fromEnvironment(
    'TRACKING_BASE_URL',
    defaultValue: 'https://tsminicab.com/track',
  );
}
