import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../core/config/env.dart';
import '../core/logging/app_logger.dart';
import '../models/duration_estimate.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import 'duration_estimator.dart';

/// Estima la duración de una tarea con Gemini, por Firebase AI Logic.
///
/// - No hay clave de API dentro de la app: Firebase autoriza la llamada.
/// - La respuesta se pide en JSON con un esquema fijo (`pomodoros`, `reason`)
///   para no tener que interpretar texto libre.
/// - Si algo falla (sin red, cuota, respuesta rara) se usa [_fallback].
class GeminiDurationEstimator implements DurationEstimator {
  GeminiDurationEstimator({
    GenerativeModel? model,
    this._fallback = const HistoryAverageEstimator(),
  }) : _model = model ?? _createModel();

  final GenerativeModel _model;
  final DurationEstimator _fallback;

  static GenerativeModel _createModel() => FirebaseAI.googleAI().generativeModel(
    model: Env.geminiModel,
    systemInstruction: Content.system(
      'Eres el asistente de Hamtimer, una app Pomodoro para estudiantes. '
      'Estimas cuántos bloques Pomodoro de 25 minutos necesita una tarea. '
      'Respondes solo con el JSON pedido.',
    ),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: Schema.object(
        properties: {
          'pomodoros': Schema.integer(description: 'Bloques de 25 min, entre 1 y 12'),
          'reason': Schema.string(description: 'Razón breve en español, máximo 15 palabras'),
        },
      ),
    ),
  );

  @override
  Future<DurationEstimate> estimate({
    required String title,
    required TaskCategory category,
    required List<Task> history,
  }) async {
    try {
      final prompt = buildPrompt(title: title, category: category, history: history);
      // Sin red la llamada puede tardar mucho en fallar: se corta a los 10 s.
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));
      final estimate = parseResponse(response.text);
      if (estimate != null) return estimate;
      AppLogger.warning('gemini', 'Respuesta no válida: ${response.text}');
    } on Exception catch (error, stack) {
      AppLogger.error('gemini', 'Falló la estimación, se usa el historial', error, stack);
    }
    return _fallback.estimate(title: title, category: category, history: history);
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
