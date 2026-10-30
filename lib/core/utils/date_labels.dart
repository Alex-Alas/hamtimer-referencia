import 'package:intl/intl.dart';

import 'date_utils.dart';

/// Formatos de fecha legibles en español para la interfaz.
///
/// Requiere `initializeDateFormatting('es')` (se hace en `main.dart`).
abstract final class DateLabels {
  static const String locale = 'es';

  static String time(DateTime value) => DateFormat.Hm(locale).format(value);

  static String shortDate(DateTime value) => DateFormat('d MMM y', locale).format(value);

  /// "Hoy, 24 oct" para el encabezado del dashboard.
  static String todayHeader(DateTime now) => 'Hoy, ${DateFormat('d MMM', locale).format(now)}';

  /// Vencimiento relativo para las tarjetas: "Hoy 10:30", "Mañana 14:00",
  /// "Ayer 09:00" o, si está más lejos, "28 oct 10:30".
  static String relativeDue(DateTime due, DateTime now) {
    final hour = time(due);
    if (due.isSameDayAs(now)) return 'Hoy $hour';
    if (due.isSameDayAs(now.add(const Duration(days: 1)))) return 'Mañana $hour';
    if (due.isSameDayAs(now.subtract(const Duration(days: 1)))) return 'Ayer $hour';
    return '${DateFormat('d MMM', locale).format(due)} $hour';
  }

  /// "hace 5 min", "hace 2 h" o la fecha corta, para el feed.
  static String timeAgo(DateTime value, DateTime now) {
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return shortDate(value);
  }
}
