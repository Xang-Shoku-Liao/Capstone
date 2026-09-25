# Banco Demo

Aplicación Android de desarrollo para emitir notificaciones de transacciones ficticias. Permite probar el futuro detector automático de `finanzas_app` sin usar cuentas ni datos bancarios reales.

## Uso

1. Ejecuta o instala Banco Demo en un teléfono Android.
2. Pulsa **Permitir notificaciones** y acepta el permiso de Android.
3. Pulsa una transacción de prueba: la aplicación publicará una notificación real del sistema.
4. Cuando Finanzas App incorpore el detector, habilita el acceso a notificaciones y autoriza el paquete `com.capstone.banco_demo` solo en modo demo.

Mensajes emitidos:

- `Compra aprobada por $12.500 en Supermercado Demo.`
- `Compra aprobada por $850 en Transporte Demo.`
- `Abono recibido por $500.000: Sueldo Demo.`
- Notificación de transferencia recibida con formato de prueba BancoEstado.

No representa a un banco real ni realiza operaciones financieras.
