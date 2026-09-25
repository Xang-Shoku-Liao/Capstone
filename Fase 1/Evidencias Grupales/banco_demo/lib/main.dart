import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BancoDemoApp());
}

class BancoDemoApp extends StatelessWidget {
  const BancoDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B5B),
          primary: const Color(0xFF006B5B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        useMaterial3: true,
      ),
      home: const BancoDemoHome(),
    );
  }
}

class BancoDemoHome extends StatefulWidget {
  const BancoDemoHome({super.key});

  @override
  State<BancoDemoHome> createState() => _BancoDemoHomeState();
}

class _BancoDemoHomeState extends State<BancoDemoHome> {
  static const _canal = MethodChannel('com.capstone.banco_demo/notificaciones');

  bool _enviando = false;
  String _estado = 'Activa las notificaciones para comenzar la prueba.';

  @override
  void initState() {
    super.initState();
    _revisarPermiso();
  }

  Future<void> _revisarPermiso() async {
    try {
      final permitido =
          await _canal.invokeMethod<bool>('tienePermisoNotificaciones') ??
          false;
      if (!mounted) return;
      setState(() {
        _estado = permitido
            ? 'Listo. Envía una transacción de prueba.'
            : 'Debes permitir las notificaciones de Banco Demo.';
      });
    } on PlatformException {
      if (mounted) {
        setState(() => _estado = 'Disponible al ejecutar en Android.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _estado = 'Disponible al ejecutar en Android.');
      }
    }
  }

  Future<void> _pedirPermiso() async {
    try {
      await _canal.invokeMethod<void>('solicitarPermisoNotificaciones');
      if (!mounted) return;
      setState(() => _estado = 'Confirma el permiso en la ventana de Android.');
    } on PlatformException {
      if (mounted) {
        setState(() => _estado = 'No fue posible solicitar el permiso.');
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _estado = 'Disponible al ejecutar en Android.');
      }
    }
  }

  Future<void> _enviarTransaccion(TransaccionDemo transaccion) async {
    setState(() => _enviando = true);
    try {
      final fechaEnvio = DateTime.now();
      final notificationId = fechaEnvio.millisecondsSinceEpoch.remainder(
        2147483647,
      );
      await _canal.invokeMethod<void>('enviarNotificacion', {
        'id': notificationId,
        'titulo': transaccion.titulo,
        'mensaje': transaccion.mensajePara(fechaEnvio),
      });
      if (!mounted) return;
      setState(() {
        _estado = 'Notificación enviada: ${transaccion.etiqueta}';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _estado = error.code == 'PERMISO_DENEGADO'
            ? 'Permite las notificaciones de Banco Demo e inténtalo otra vez.'
            : 'No se pudo enviar la notificación.';
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const transacciones = [
      TransaccionDemo(
        titulo: 'Banco Demo',
        etiqueta: 'Compra en supermercado',
        mensaje: 'Compra aprobada por \$12.500 en Supermercado Demo.',
        icono: Icons.shopping_cart_outlined,
        color: Color(0xFFC4472A),
      ),
      TransaccionDemo(
        titulo: 'Banco Demo',
        etiqueta: 'Pago de transporte',
        mensaje: 'Compra aprobada por \$850 en Transporte Demo.',
        icono: Icons.directions_bus_outlined,
        color: Color(0xFF6A5ACD),
      ),
      TransaccionDemo(
        titulo: 'Banco Demo',
        etiqueta: 'Depósito de sueldo',
        mensaje: 'Abono recibido por \$500.000: Sueldo Demo.',
        icono: Icons.account_balance_wallet_outlined,
        color: Color(0xFF1D9E75),
      ),
      TransaccionDemo(
        titulo: 'Transferencia',
        etiqueta: 'Transferencia recibida · formato BancoEstado',
        mensaje: '',
        generadorMensaje: _mensajeTransferenciaBancoEstadoDemo,
        icono: Icons.swap_horiz_outlined,
        color: Color(0xFF1D6FA5),
      ),
      TransaccionDemo(
        titulo: 'Transferencia',
        etiqueta: 'Transferencia enviada · formato BancoEstado',
        mensaje: '',
        generadorMensaje: _mensajeTransferenciaEnviadaBancoEstadoDemo,
        icono: Icons.north_east_outlined,
        color: Color(0xFFC4472A),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco Demo'),
        backgroundColor: const Color(0xFF013A40),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF006B5B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulador de transacciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Genera notificaciones Android reales para probar la '
                    'detección automática de Finanzas App.',
                    style: TextStyle(color: Color(0xFFD6E8E5), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD8E2E0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF006B5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_estado, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pedirPermiso,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Permitir notificaciones'),
            ),
            const SizedBox(height: 22),
            const Text(
              'Transacciones de prueba',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...transacciones.map(
              (transaccion) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BotonTransaccion(
                  transaccion: transaccion,
                  deshabilitado: _enviando,
                  onPressed: () => _enviarTransaccion(transaccion),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Uso exclusivo para desarrollo. No representa una institución '
              'financiera real ni usa datos bancarios.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonTransaccion extends StatelessWidget {
  const _BotonTransaccion({
    required this.transaccion,
    required this.deshabilitado,
    required this.onPressed,
  });

  final TransaccionDemo transaccion;
  final bool deshabilitado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: deshabilitado ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD8E2E0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: transaccion.color.withValues(alpha: 0.12),
                foregroundColor: transaccion.color,
                child: Icon(transaccion.icono),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaccion.etiqueta,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaccion.mensajePara(DateTime.now()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.send_outlined, color: Color(0xFF006B5B)),
            ],
          ),
        ),
      ),
    );
  }
}

class TransaccionDemo {
  const TransaccionDemo({
    required this.titulo,
    required this.etiqueta,
    required this.mensaje,
    this.generadorMensaje,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String etiqueta;
  final String mensaje;
  final String Function(DateTime)? generadorMensaje;
  final IconData icono;
  final Color color;

  String mensajePara(DateTime fecha) {
    return generadorMensaje?.call(fecha) ?? mensaje;
  }
}

String _mensajeTransferenciaBancoEstadoDemo(DateTime fecha) {
  final fechaTexto =
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}:'
      '${fecha.second.toString().padLeft(2, '0')}';
  return 'Estimado/a Usuario Demo, te informamos que con fecha $fechaTexto '
      'has recibido una transferencia de Remitente Demo por \$1.000 '
      'a tu CuentaRUT 0000.';
}

String _mensajeTransferenciaEnviadaBancoEstadoDemo(DateTime fecha) {
  final fechaTexto =
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}:'
      '${fecha.second.toString().padLeft(2, '0')}';
  return 'Estimado/a Usuario Demo, te informamos que con fecha $fechaTexto '
      'has realizado una transferencia a Destinatario Demo por \$1.000 '
      'a su CuentaRUT ****0000 de Banco Demo.';
}
