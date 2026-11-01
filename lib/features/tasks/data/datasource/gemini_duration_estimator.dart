import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/duration_estimate.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/repositories/duration_estimator.dart';

/// Estima la duración de una tarea con Gemini, llamando directo a la
/// Gemini API (`generateContent`) con una clave de Google AI Studio.
///
/// - La clave llega por `GEMINI_API_KEY` en `env/local.json`, que no se sube
///   al repo. Sin clave no se llama a Gemini y se usa [_fallback].
/// - La respuesta se pide en JSON con un esquema fijo (`pomodoros`, `reason`)
///   para no tener que interpretar texto libre.
/// - Si algo falla (sin red, cuota, respuesta rara) se usa [_fallback].
class GeminiDurationEstimator implements DurationEstimator {
  GeminiDurationEstimator({
    Dio? dio,
    this._apiKey = Env.geminiApiKey,
    this._model = Env.geminiModel,
    this._fallback = const HistoryAverageEstimator(),
  }) : _dio = dio ?? Dio(_baseOptions);

  final Dio _dio;
  final String _apiKey;
  final String _model;
  final DurationEstimator _fallback;

  // Sin red la llamada puede tardar mucho en fallar: se corta a los 10 s.
  static final _baseOptions = BaseOptions(
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  static const _systemInstruction =
      'Eres el asistente de Hamtimer, una app Pomodoro para estudiantes. '
      'Estimas cuántos bloques Pomodoro de 25 minutos necesita una tarea. '
      'Respondes solo con el JSON pedido.';

  @override
  Future<DurationEstimate> estimate({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  }) async {
    if (_apiKey.isEmpty) {
      AppLogger.warning('gemini', 'Falta GEMINI_API_KEY, se usa el historial');
      return _fallback.estimate(title: title, category: category, history: history);
    }
    try {
      final prompt = buildPrompt(title: title, category: category, history: history);
      final response = await _dio.post<Map<String, dynamic>>(
        'models/$_model:generateContent',
        options: Options(headers: {'x-goog-api-key': _apiKey}),
        data: buildRequest(prompt),
      );
      final text = extractText(response.data);
      final estimate = parseResponse(text);
      if (estimate != null) return estimate;
      AppLogger.warning('gemini', 'Respuesta no válida: $text');
    } on DioException catch (error, stack) {
      // El cuerpo del error trae la causa (cuota, modelo, clave inválida).
      AppLogger.error('gemini', 'Falló la estimación: ${error.response?.data}', error, stack);
    } on Exception catch (error, stack) {
      AppLogger.error('gemini', 'Falló la estimación, se usa el historial', error, stack);
    }
    return _fallback.estimate(title: title, category: category, history: history);
  }

  /// Cuerpo de `generateContent`: instrucción de sistema, el prompt y el
  /// esquema JSON de la respuesta.
  static Map<String, dynamic> buildRequest(String prompt) => {
    'systemInstruction': {
      'parts': [
        {'text': _systemInstruction},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      },
    ],
    'generationConfig': {
      'temperature': 0.2,
      'responseMimeType': 'application/json',
      'responseSchema': {
        'type': 'OBJECT',
        'properties': {
          'pomodoros': {'type': 'INTEGER', 'description': 'Bloques de 25 min, entre 1 y 12'},
          'reason': {'type': 'STRING', 'description': 'Razón breve en español, máximo 15 palabras'},
        },
        'required': ['pomodoros', 'reason'],
      },
    },
  };

  /// Saca el texto de la primera respuesta (`candidates[0].content.parts`).
  static String? extractText(Map<String, dynamic>? body) {
    final candidates = body?['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final parts = (candidates.first as Map<String, dynamic>)['content']?['parts'];
    if (parts is! List) return null;
    return parts.map((part) => (part as Map<String, dynamic>)['text'] ?? '').join();
  }

  /// Arma el mensaje con la tarea nueva y el historial real del usuario.
  static String buildPrompt({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  }) {
    final buffer = StringBuffer()
      ..writeln('Tarea nueva: "$title" (categoría: ${category.label}).')
      ..writeln();
    if (history.isEmpty) {
      buffer.writeln('El usuario aún no tiene tareas completadas.');
    } else {
      buffer.writeln('Tareas que el usuario ya completó (Pomodoros reales):');
      for (final task in history.take(20)) {
        buffer.writeln('- "${task.title}" (${task.category.label}): ${task.completedPomodoros}');
      }
    }
    buffer
      ..writeln()
      ..writeln('¿Cuántos Pomodoros necesita la tarea nueva?');
    return buffer.toString();
  }

  /// Convierte el JSON de Gemini en una estimación, o `null` si no sirve.
  static DurationEstimate? parseResponse(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      final pomodoros = (json['pomodoros'] as num?)?.round();
      if (pomodoros == null) return null;
      return DurationEstimate(
        pomodoros: pomodoros.clamp(1, 12),
        reason: (json['reason'] as String?)?.trim() ?? 'Estimación de Gemini',
        source: EstimateSource.ai,
      );
    } on FormatException {
      return null;
    }
  }
}
