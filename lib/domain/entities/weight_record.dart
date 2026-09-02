/// Registro de peso del "día de pesaje oficial".
///
/// El control es semanal (no diario) para evitar el ruido de las
/// fluctuaciones naturales. El día oficial se configura en [AppSettings].
class WeightRecord {
  final String id;
  final DateTime date; // fecha del pesaje (normalizada a medianoche)
  final double weightKg;

  /// Origen del registro: 'official' | 'manual' | 'import_3m'.
  final String source;

  const WeightRecord({
    required this.id,
    required this.date,
    required this.weightKg,
    this.source = 'manual',
  });

  WeightRecord copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    String? source,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is WeightRecord && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WeightRecord($id, $date, ${weightKg}kg, $source)';
}
