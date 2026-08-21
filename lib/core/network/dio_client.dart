import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around dio: attaches the JWT to every request, converts
/// DioExceptions into [ApiException], and calls [onUnauthorized] once on a
/// 401 so the app can clear the session and drop back to login.
class ApiClient {
  ApiClient({required SecureStorage secureStorage, required this.onUnauthorized})
      : _secureStorage = secureStorage,
        _dio = Dio(BaseOptions(baseUrl: '${Env.apiBaseUrl}/api')) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStorage _secureStorage;
  final void Function() onUnauthorized;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: query));

  Future<Response<List<int>>> getBytes(String path, {Map<String, dynamic>? query}) => _run(
        () => _dio.get<List<int>>(
          path,
          queryParameters: query,
          options: Options(responseType: ResponseType.bytes),
        ),
      );

  Future<Response<dynamic>> post(String path, {dynamic data}) =>
      _run(() => _dio.post(path, data: data));

  Future<Response<dynamic>> patch(String path, {dynamic data}) =>
      _run(() => _dio.patch(path, data: data));

  Future<Response<dynamic>> delete(String path) => _run(() => _dio.delete(path));

  Future<Response<dynamic>> postMultipart(String path, FormData formData) =>
      _run(() => _dio.post(path, data: formData));

  Future<Response<dynamic>> patchMultipart(String path, FormData formData) => _run(
        () => _dio.patch(
          path,
          data: formData,
          options: Options(method: 'PATCH'),
        ),
      );

  Future<Response<T>> _run<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = e.message ?? 'Network error';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is Map && data['error'] is String) {
      message = data['error'] as String;
    }
    return ApiException(statusCode: statusCode, message: message, data: data);
  }
}
