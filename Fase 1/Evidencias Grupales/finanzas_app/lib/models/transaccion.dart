class Transaccion {
  final int? id;
  final int categoriaId;
  final double monto;
  final String fecha; // formato 'yyyy-MM-dd'
  final String descripcion;
  final String tipo; // 'ingreso' o 'gasto'
  final String origen; // 'manual' o 'automatico'
  final String estado; // 'confirmado' o 'pendiente'
  final String? institucion;
  final String? hora; // formato opcional 'HH:mm:ss'

  Transaccion({
    this.id,
    required this.categoriaId,
    required this.monto,
    required this.fecha,
    this.descripcion = '',
    required this.tipo,
    this.origen = 'manual',
    this.estado = 'confirmado',
    this.institucion,
    this.hora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'monto': monto,
      'fecha': fecha,
      'descripcion': descripcion,
      'tipo': tipo,
      'origen': origen,
      'estado': estado,
      'institucion': institucion,
      'hora': hora,
    };
  }

  factory Transaccion.fromMap(Map<String, dynamic> map) {
    return Transaccion(
      id: map['id'] as int?,
      categoriaId: map['categoria_id'] as int,
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      tipo: map['tipo'] as String,
      origen: map['origen'] as String? ?? 'manual',
      estado: map['estado'] as String? ?? 'confirmado',
      institucion: map['institucion'] as String?,
      hora: map['hora'] as String?,
    );
  }

  Transaccion copyWith({
    int? id,
    int? categoriaId,
    double? monto,
    String? fecha,
    String? descripcion,
    String? tipo,
    String? origen,
    String? estado,
    String? institucion,
    String? hora,
  }) {
    return Transaccion(
      id: id ?? this.id,
      categoriaId: categoriaId ?? this.categoriaId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      origen: origen ?? this.origen,
      estado: estado ?? this.estado,
      institucion: institucion ?? this.institucion,
      hora: hora ?? this.hora,
    );
  }

  @override
  String toString() =>
      'Transaccion(id: $id, categoriaId: $categoriaId, monto: $monto, fecha: $fecha, tipo: $tipo, origen: $origen, estado: $estado, institucion: $institucion, hora: $hora)';
}
