import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/tasks/data/datasource/gemini_duration_estimator.dart';
import 'package:hamtimer/features/tasks/domain/entities/duration_estimate.dart';
import 'package:hamtimer/features/tasks/domain/entities/task_category.dart';

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

  test('llama a generateContent con la clave y, sin clave, usa el historial', () async {
    RequestOptions? sent;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {'text': '{"pomodoros": 3, "reason": "Parecida al Lab 1"}'},
                        ],
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
    final history = [buildTask(title: 'Lab 1', completed: 3, isCompleted: true)];

    final estimate = await GeminiDurationEstimator(dio: dio, apiKey: 'clave-de-prueba').estimate(
      title: 'Lab 2',
      category: TaskCategory.study,
      history: history,
    );
    expect(estimate.pomodoros, 3);
    expect(estimate.source, EstimateSource.ai);
    expect(sent?.path, endsWith(':generateContent'));
    expect(sent?.headers['x-goog-api-key'], 'clave-de-prueba');

    sent = null;
    final offline = await GeminiDurationEstimator(dio: dio, apiKey: '').estimate(
      title: 'Lab 2',
      category: TaskCategory.study,
      history: history,
    );
    expect(sent, isNull);
    expect(offline.source, EstimateSource.history);
  });
}
