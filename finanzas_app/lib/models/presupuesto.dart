class Presupuesto {
  final int? id;
  final int categoriaId;
  final double montoLimite;
  final String mes; // formato 'yyyy-MM'

  Presupuesto({
    this.id,
    required this.categoriaId,
    required this.montoLimite,
    required this.mes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'monto_limite': montoLimite,
      'mes': mes,
    };
  }

  factory Presupuesto.fromMap(Map<String, dynamic> map) {
    return Presupuesto(
      id: map['id'] as int?,
      categoriaId: map['categoria_id'] as int,
      montoLimite: (map['monto_limite'] as num).toDouble(),
      mes: map['mes'] as String,
    );
  }

  @override
  String toString() =>
      'Presupuesto(id: $id, categoriaId: $categoriaId, montoLimite: $montoLimite, mes: $mes)';
}
