class Categoria {
  final int? id;
  final String nombre;
  final String tipo; // 'ingreso' o 'gasto'

  Categoria({
    this.id,
    required this.nombre,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
    );
  }

  @override
  String toString() => 'Categoria(id: $id, nombre: $nombre, tipo: $tipo)';
}
