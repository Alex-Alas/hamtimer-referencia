import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../models/task.dart';
import '../../models/task_query.dart';
import 'task_json_mapper.dart';
import 'task_remote_data_source.dart';

/// Fuente remota de tareas sobre la API REST de MockAPI.io, con Dio.
///
/// Endpoints:
/// - `GET  /tasks?userId=&page=&limit=&category=&isCompleted=`  dashboard
/// - `POST /tasks`                                              formulario
/// - `PUT  /tasks/:id`                                          Pomodoro y check
class MockApiTaskRemoteDataSource implements TaskRemoteDataSource {
  MockApiTaskRemoteDataSource(this._dio);

  final Dio _dio;

  static const _path = '/tasks';

  @override
  Future<List<Task>> fetchPage(String userId, TaskQuery query) {
    return _getList({
      'userId': userId,
      'page': query.page,
      'limit': query.limit,
      // Las más próximas a vencer primero: lo urgente queda arriba.
      'sortBy': 'dueAt',
      'order': 'asc',
      if (query.category != null) 'category': query.category!.apiValue,
      if (query.isCompleted != null) 'isCompleted': query.isCompleted,
    });
  }

  @override
  Future<List<Task>> fetchAll(String userId) =>
      _getList({'userId': userId, 'sortBy': 'dueAt', 'order': 'asc'});

  @override
  Future<List<Task>> fetchCompleted(String userId, {required int limit}) => _getList({
    'userId': userId,
    'isCompleted': true,
    'sortBy': 'createdAt',
    'order': 'desc',
    'page': 1,
    'limit': limit,
  });

  @override
  Future<Task> create(String userId, TaskDraft draft) async {
    final data = await _send(
      () => _dio.post<Object?>(_path, data: TaskJsonMapper.draftToJson(userId, draft)),
    );
    return TaskJsonMapper.fromJson(_asObject(data));
  }

  @override
  Future<Task> update(String userId, Task task) async {
    final data = await _send(
      () => _dio.put<Object?>('$_path/${task.id}', data: TaskJsonMapper.toJson(userId, task)),
    );
    return TaskJsonMapper.fromJson(_asObject(data));
  }

  Future<List<Task>> _getList(Map<String, Object?> query) async {
    final data = await _send(
      () => _dio.get<Object?>(_path, queryParameters: query),
      // Particularidad de MockAPI: cuando un filtro no tiene coincidencias
      // responde 404 "Not found" en lugar de una lista vacía.
      emptyOnNotFound: true,
    );
    if (data == null) return const [];
    if (data is! List) throw const AppException('Respuesta inesperada del servidor');
    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskJsonMapper.fromJson)
        .where((task) => task.title.isNotEmpty)
        .toList(growable: false);
  }

  /// Ejecuta la petición y traduce los errores de Dio a errores de la app.
  Future<Object?> _send(
    Future<Response<Object?>> Function() request, {
    bool emptyOnNotFound = false,
  }) async {
    try {
      return (await request()).data;
    } on DioException catch (error) {
      if (emptyOnNotFound && error.response?.statusCode == 404) return null;
      throw switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => const NetworkException(
          'El servidor tardó demasiado en responder',
        ),
        DioExceptionType.connectionError || DioExceptionType.unknown => const NetworkException(),
        _ => AppException('Error del servidor (${error.response?.statusCode ?? '?'})'),
      };
    }
  }

  Map<String, dynamic> _asObject(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const AppException('Respuesta inesperada del servidor');
    }
    return data;
  }
}
