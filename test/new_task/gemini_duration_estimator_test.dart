import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/models/duration_estimate.dart';
import 'package:hamtimer/models/task_category.dart';
import 'package:hamtimer/services/gemini_duration_estimator.dart';

import '../fakes/task_factory.dart';

void main() {
  test('el prompt lleva el historial y la respuesta JSON de Gemini se valida', () {
    final prompt = GeminiDurationEstimator.buildPrompt(
      title: 'Parcial de Dart',
      category: TaskCategory.study,
      history: [buildTask(title: 'Lab 1', completed: 3, isCompleted: true)],
    );
    expect(prompt, contains('"Parcial de Dart"'));
    expect(prompt, contains('"Lab 1" (Estudio): 3'));

    final estimate = GeminiDurationEstimator.parseResponse(
      '{"pomodoros": 4, "reason": "Como el Lab 1"}',
    );
    expect(estimate?.pomodoros, 4);
    expect(estimate?.source, EstimateSource.ai);

    // Fuera de rango se recorta; texto que no es JSON se descarta.
    expect(GeminiDurationEstimator.parseResponse('{"pomodoros": 40}')?.pomodoros, 12);
    expect(GeminiDurationEstimator.parseResponse('cuatro pomodoros'), isNull);
  });
}
