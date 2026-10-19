import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/models/transaccion.dart';

void main() {
  test('un movimiento conserva sus datos de detección automática', () {
    final movimiento = Transaccion(
      id: 8,
      categoriaId: 2,
      monto: 1250,
      fecha: '2026-10-19',
      tipo: 'gasto',
      origen: 'automatico',
      institucion: 'BancoEstado',
      hora: '17:51:14',
    );

    final recategorizado = movimiento.copyWith(categoriaId: 5);

    expect(recategorizado.categoriaId, 5);
    expect(recategorizado.origen, 'automatico');
    expect(recategorizado.institucion, 'BancoEstado');
  });
}
