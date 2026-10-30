import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/models/pomodoro_settings.dart';
import 'package:hamtimer/repositories/prefs_pomodoro_settings_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('las duraciones se guardan en SharedPreferences y se vuelven a leer', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final repository = PrefsPomodoroSettingsRepository();

    // Sin nada guardado: los valores estándar.
    expect((await repository.load()).focus, const Duration(minutes: 25));

    await repository.save(
      PomodoroSettings.standard.copyWith(
        focus: const Duration(minutes: 50),
        longBreak: const Duration(minutes: 30),
      ),
    );
    final loaded = await PrefsPomodoroSettingsRepository().load();
    expect(loaded.focus, const Duration(minutes: 50));
    expect(loaded.shortBreak, const Duration(minutes: 5));
    expect(loaded.longBreak, const Duration(minutes: 30));
  });
}
