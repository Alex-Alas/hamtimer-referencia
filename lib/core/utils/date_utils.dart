/// Utilidades de fecha sin dependencias de UI.
extension DateOnly on DateTime {
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Combina la fecha de `this` con la hora de [hour]/[minute].
  DateTime withTime(int hour, int minute) => DateTime(year, month, day, hour, minute);
}
