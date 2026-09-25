import 'package:flutter_test/flutter_test.dart';

import 'package:banco_demo/main.dart';

void main() {
  testWidgets('muestra las transacciones de prueba', (tester) async {
    await tester.pumpWidget(const BancoDemoApp());
    await tester.pump();

    expect(find.text('Banco Demo'), findsOneWidget);
    expect(find.text('Compra en supermercado'), findsOneWidget);
    expect(find.text('Pago de transporte'), findsOneWidget);
    expect(find.text('Depósito de sueldo'), findsOneWidget);
  });
}
