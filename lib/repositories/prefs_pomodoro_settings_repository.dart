import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro_settings.dart';
import 'pomodoro_settings_repository.dart';

/// Guarda las duraciones del Pomodoro con SharedPreferences (clase 25).
///
/// Son tres enteros sueltos (minutos), justo el caso para el que existe
/// SharedPreferences: pares clave-valor que sobreviven al cerrar la app.
class PrefsPomodoroSettingsRepository implements PomodoroSettingsRepository {
  PrefsPomodoroSettingsRepository({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _focusKey = 'pomodoro.focus_minutes';
  static const _shortBreakKey = 'pomodoro.short_break_minutes';
  static const _longBreakKey = 'pomodoro.long_break_minutes';

  @override
  Future<PomodoroSettings> load() async {
    const defaults = PomodoroSettings.standard;
    final focus = await _prefs.getInt(_focusKey);
    final shortBreak = await _prefs.getInt(_shortBreakKey);
    final longBreak = await _prefs.getInt(_longBreakKey);
    return defaults.copyWith(
      focus: focus == null ? null : Duration(minutes: focus),
      shortBreak: shortBreak == null ? null : Duration(minutes: shortBreak),
      longBreak: longBreak == null ? null : Duration(minutes: longBreak),
    );
  }

  @override
  Future<void> save(PomodoroSettings settings) async {
    await _prefs.setInt(_focusKey, settings.focus.inMinutes);
    await _prefs.setInt(_shortBreakKey, settings.shortBreak.inMinutes);
    await _prefs.setInt(_longBreakKey, settings.longBreak.inMinutes);
  }
}
