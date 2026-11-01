import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/pomodoro/domain/entities/pomodoro_settings.dart';
import 'package:hamtimer/features/pomodoro/domain/usecases/load_pomodoro_settings_usecase.dart';
import 'package:hamtimer/features/pomodoro/domain/usecases/save_pomodoro_settings_usecase.dart';
import 'package:hamtimer/features/pomodoro/presentation/providers/pomodoro_provider.dart';

import '../fakes/fake_pomodoro_collaborators.dart';
import '../fakes/task_factory.dart';

void main() {
  test('al terminar el enfoque registra el Pomodoro, da puntos y pasa al descanso', () async {
    var now = DateTime(2026, 11, 1, 9);
    final recorder = FakeProgressRecorder();
    final settings = FakePomodoroSettingsRepository();
    final provider = PomodoroProvider(
      recorder: recorder,
      loadSettings: LoadPomodoroSettingsUseCase(settings),
      saveSettings: SavePomodoroSettingsUseCase(settings),
      demoMode: true, // bloques de 10 s
      clock: () => now,
    );
    final task = buildTask(estimated: 1);
    provider.addToQueue([task]);
    final events = <PomodoroEvent>[];
    provider.events.listen(events.add);

    provider.start();
    now = now.add(PomodoroSettings.demo.focus);
    provider.tick();
    await Future<void>.delayed(Duration.zero);

    expect(recorder.recorded.single.id, task.id);
    final finished = events.single as FocusBlockFinished;
    expect(finished.nextBreak, PomodoroPhase.shortBreak);
    expect(finished.pointsEarned, 35); // 10 por bloque + 25 por completar la tarea
    expect(provider.phase, PomodoroPhase.shortBreak);
    expect(provider.queue, isEmpty); // la tarea completada sale de la cola
    provider.dispose();
  });
}
