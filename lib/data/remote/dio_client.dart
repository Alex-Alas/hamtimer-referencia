import 'package:dio/dio.dart';

import '../../core/config/env.dart';
import '../../core/logging/app_logger.dart';

/// Crea el cliente Dio de la app con tiempos de espera y bitácora (clase 21).
Dio createDioClient({String baseUrl = Env.apiBaseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Env.requestTimeout,
      receiveTimeout: Env.requestTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(LoggingInterceptor());
  return dio;
}

/// Interceptor que deja en la bitácora cada petición, su respuesta y sus
/// errores. Sirve para depurar con DevTools sin poner `print` en el código.
class LoggingInterceptor extends Interceptor {
  static const _source = 'http';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info(_source, '→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      _source,
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.warning(
      _source,
      '✕ ${err.type.name} ${err.requestOptions.method} ${err.requestOptions.uri} '
      '(${err.response?.statusCode ?? 'sin respuesta'})',
    );
    handler.next(err);
  }
}
