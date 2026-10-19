class MetaAhorro {
  final int? id;
  final String nombre;
  final double montoObjetivo;
  final double montoActual;
  final String fechaCreacion;

  const MetaAhorro({
    this.id,
    required this.nombre,
    required this.montoObjetivo,
    this.montoActual = 0,
    required this.fechaCreacion,
  });

  double get montoFaltante =>
      (montoObjetivo - montoActual).clamp(0, montoObjetivo).toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto_objetivo': montoObjetivo,
      'monto_actual': montoActual,
      'fecha_creacion': fechaCreacion,
    };
  }

  factory MetaAhorro.fromMap(Map<String, dynamic> map) {
    return MetaAhorro(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      montoObjetivo: (map['monto_objetivo'] as num).toDouble(),
      montoActual: (map['monto_actual'] as num).toDouble(),
      fechaCreacion: map['fecha_creacion'] as String,
    );
  }

  MetaAhorro copyWith({
    String? nombre,
    double? montoObjetivo,
    double? montoActual,
  }) {
    return MetaAhorro(
      id: id,
      nombre: nombre ?? this.nombre,
      montoObjetivo: montoObjetivo ?? this.montoObjetivo,
      montoActual: montoActual ?? this.montoActual,
      fechaCreacion: fechaCreacion,
    );
  }
}
