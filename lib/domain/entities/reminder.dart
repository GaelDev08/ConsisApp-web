/// Entidad independiente de recordatorio.
class Reminder {
  final String id;
  final String title;
  final String time; // "HH:mm" (ej. "15:30")
  final bool enabled;
  final String frequency; // 'daily', 'weekly', 'once'
  final DateTime? date; // Optional date for 'once' or start date

  const Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.enabled = true,
    this.frequency = 'daily',
    this.date,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? time,
    bool? enabled,
    String? frequency,
    DateTime? date,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      date: date ?? this.date,
    );
  }
}
