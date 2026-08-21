/// Wraps a failed API call. [statusCode] is null for network-level failures
/// (no connectivity, timeout) that never reached the server.
class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.data});

  final int? statusCode;
  final String message;
  final dynamic data;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
