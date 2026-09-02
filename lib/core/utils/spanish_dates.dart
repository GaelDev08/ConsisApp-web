import 'datetime_x.dart';

/// Formateo de fechas en español sin depender de `intl/locale` (web-safe).
///
/// Convención de la tira semanal española: L M X J V S D.
const List<String> kWeekdayNamesEs = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const List<String> kMonthNamesEs = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Letras cortas para la tira semanal (índice = weekday - 1).
const List<String> kWeekdayStripEs = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// "sábado, 26 de septiembre"
String formatDateEs(DateTime d) =>
    '${kWeekdayNamesEs[d.weekday - 1]}, ${d.day} de ${kMonthNamesEs[d.month - 1]}';

/// "26 de septiembre"
String formatDayMonthEs(DateTime d) =>
    '${d.day} de ${kMonthNamesEs[d.month - 1]}';

/// Etiqueta inteligente: "Hoy", "Ayer" o "lunes, 24 de agosto".
String formatSmartDateEs(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (d.isSameDayAs(n)) return 'Hoy';
  if (d.isSameDayAs(n.subtract(const Duration(days: 1)))) return 'Ayer';
  return formatDateEs(d);
}
