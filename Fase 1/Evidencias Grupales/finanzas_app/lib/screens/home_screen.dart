import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../models/presupuesto.dart';
import '../models/transaccion.dart';
import 'add_transaction_screen.dart';
import 'categories_screen.dart';
import 'savings_goals_screen.dart';
import 'transaction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _db = DatabaseHelper.instance;
  static const _detectorChannel = MethodChannel(
    'com.capstone.finanzas_app/detector',
  );

  static const _background = Color(0xFF0B1014);
  static const _surface = Color(0xFF141F26);
  static const _cyan = Color(0xFF31D9D0);
  static const _emerald = Color(0xFF42D392);
  static const _violet = Color(0xFF8B7CFF);
  static const _danger = Color(0xFFFF8F87);
  static const _text = Color(0xFFF2FFFC);
  static const _muted = Color(0xFF8EA2A5);

  double _ingresos = 0;
  double _gastos = 0;
  double _ingresosMes = 0;
  double _gastosMes = 0;
  Map<String, double> _gastosPorCategoriaMes = {};
  List<Transaccion> _movimientos = [];
  List<Presupuesto> _presupuestos = [];
  Map<int, Categoria> _categoriasPorId = {};
  bool _cargando = true;
  String? _errorCarga;
  bool _detectorActivo = false;
  bool _ocultarSaldo = false;
  int _seccionActual = 0;
  String _filtroActividad = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectorChannel.setMethodCallHandler((call) async {
      if (call.method == 'transaccionAutomaticaRegistrada') {
        await _cargarDatos();
      }
    });
    _cargarDatos();
    _cargarEstadoDetector();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectorChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cargarEstadoDetector();
      _cargarDatos();
    }
  }

  Future<void> _cargarEstadoDetector() async {
    if (!Platform.isAndroid) return;
    try {
      final activo =
          await _detectorChannel.invokeMethod<bool>('detectorActivo') ?? false;
      if (mounted) setState(() => _detectorActivo = activo);
    } on PlatformException {
      // El detector solo existe en Android.
    } on MissingPluginException {
      // Permite trabajar con la aplicación en escritorio.
    }
  }

  Future<void> _activarDetector() async {
    try {
      await _detectorChannel.invokeMethod<void>('abrirAjustesDetector');
    } on PlatformException {
      if (mounted) _mensaje('No se pudieron abrir los ajustes.');
    } on MissingPluginException {
      if (mounted) _mensaje('Disponible solo en Android.');
    }
  }

  Future<void> _cargarDatos() async {
    if (mounted) setState(() => _cargando = true);
    try {
      final mes = _mesClave(DateTime.now());
      final categorias = await _db.getCategorias();
      final ingresos = await _db.getTotalPorTipo('ingreso');
      final gastos = await _db.getTotalPorTipo('gasto');
      final ingresosMes = await _db.getTotalPorTipo('ingreso', mes: mes);
      final gastosMes = await _db.getTotalPorTipo('gasto', mes: mes);
      final porCategoria = await _db.getGastosPorCategoria(mes: mes);
      final movimientos = await _db.getTransacciones();
      final presupuestos = await _db.getPresupuestos(mes);
      if (!mounted) return;
      setState(() {
        _categoriasPorId = {for (final item in categorias) item.id!: item};
        _ingresos = ingresos;
        _gastos = gastos;
        _ingresosMes = ingresosMes;
        _gastosMes = gastosMes;
        _gastosPorCategoriaMes = porCategoria;
        _movimientos = movimientos;
        _presupuestos = presupuestos;
        _errorCarga = null;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCarga = 'No se pudieron cargar tus datos.';
      });
    }
  }

  Future<void> _irAAgregar({String? tipoInicial}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(tipoInicial: tipoInicial),
      ),
    );
    if (resultado == true) _cargarDatos();
  }

  Future<void> _verDetalle(Transaccion transaccion) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          transaccion: transaccion,
          categoriaInicial: _categoriasPorId[transaccion.categoriaId],
        ),
      ),
    );
    if (resultado == true) _cargarDatos();
  }

  Future<void> _abrirCategorias() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
    );
    if (mounted) _cargarDatos();
  }

  Future<void> _abrirMetasAhorro() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
    );
  }

  Future<void> _reiniciarDatosPrueba() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar datos de prueba?'),
        content: const Text(
          'Se eliminarán todos los ingresos, gastos, presupuestos y metas de ahorro. Tus categorías se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFFFF8F87),
            ),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _db.reiniciarDatosDePrueba();
    await _cargarDatos();
    if (mounted) {
      _mensaje('Datos de prueba reiniciados. Tu saldo quedó en \$0.');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A2A30),
        content: Text(texto),
      ),
    );
  }

  String _mesClave(DateTime fecha) =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';

  String _mesLegible(DateTime fecha) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  String _fmt(double valor) {
    final entero = valor.round();
    final texto = entero.abs().toString();
    final salida = StringBuffer();
    for (var index = 0; index < texto.length; index++) {
      if (index > 0 && (texto.length - index) % 3 == 0) salida.write('.');
      salida.write(texto[index]);
    }
    return '${entero < 0 ? '-' : ''}\$$salida';
  }

  double? _montoDesdeTexto(String texto) {
    final limpio = texto
        .trim()
        .replaceAll(r'$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(limpio);
  }

  Future<void> _gestionarPresupuesto([Presupuesto? existente]) async {
    final categoriasGasto =
        _categoriasPorId.values
            .where((categoria) => categoria.tipo == 'gasto')
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
    if (categoriasGasto.isEmpty) {
      _mensaje('Primero crea una categoría de gasto.');
      return;
    }

    var categoriaId = existente?.categoriaId ?? categoriasGasto.first.id!;
    final monto = TextEditingController(
      text: existente == null ? '' : existente.montoLimite.round().toString(),
    );
    String? error;
    final resultado = await showDialog<_DatosPresupuesto>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) => AlertDialog(
          title: Text(
            existente == null ? 'Nuevo presupuesto' : 'Editar presupuesto',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: categoriaId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categoriasGasto
                    .map(
                      (categoria) => DropdownMenuItem(
                        value: categoria.id,
                        child: Text(categoria.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  if (valor != null) actualizar(() => categoriaId = valor);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monto,
                autofocus: existente == null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Límite mensual',
                  prefixText: r'$ ',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 9),
                Text(
                  error!,
                  style: const TextStyle(color: _danger, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            if (existente != null)
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, const _DatosPresupuesto.eliminar()),
                style: TextButton.styleFrom(foregroundColor: _danger),
                child: const Text('Eliminar'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final limite = _montoDesdeTexto(monto.text);
                if (limite == null || limite <= 0) {
                  actualizar(() => error = 'Ingresa un límite válido.');
                  return;
                }
                Navigator.pop(
                  context,
                  _DatosPresupuesto(
                    categoriaId: categoriaId,
                    montoLimite: limite,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _background,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => monto.dispose());
    if (resultado == null) return;

    if (resultado.eliminar) {
      await _db.deletePresupuesto(existente!.id!);
      await _cargarDatos();
      if (mounted) _mensaje('Presupuesto eliminado.');
      return;
    }

    if (existente != null && existente.categoriaId != resultado.categoriaId) {
      await _db.deletePresupuesto(existente.id!);
    }
    await _db.insertOrUpdatePresupuesto(
      Presupuesto(
        categoriaId: resultado.categoriaId,
        montoLimite: resultado.montoLimite,
        mes: _mesClave(DateTime.now()),
      ),
    );
    await _cargarDatos();
    if (mounted) _mensaje('Presupuesto guardado.');
  }

  IconData _iconoCategoria(String? nombre) {
    final texto = (nombre ?? '').toLowerCase();
    if (texto.contains('comida') ||
        texto.contains('aliment') ||
        texto.contains('super')) {
      return Icons.shopping_basket_outlined;
    }
    if (texto.contains('transporte') || texto.contains('movilidad')) {
      return Icons.directions_bus_outlined;
    }
    if (texto.contains('salud')) return Icons.favorite_border_rounded;
    if (texto.contains('ocio') || texto.contains('entreten')) {
      return Icons.movie_outlined;
    }
    if (texto.contains('sueldo')) return Icons.payments_outlined;
    return Icons.category_outlined;
  }

  double get _saldo => _ingresos - _gastos;
  double get _limiteTotal =>
      _presupuestos.fold<double>(0, (suma, item) => suma + item.montoLimite);

  List<MapEntry<String, double>> get _categoriasPrincipales {
    final entradas = _gastosPorCategoriaMes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas.take(3).toList();
  }

  List<double> _tendenciaSemana() {
    final hoy = DateTime.now();
    final neto = List<double>.filled(7, 0);
    for (final movimiento in _movimientos) {
      final fecha = DateTime.tryParse(movimiento.fecha);
      if (fecha == null) continue;
      final diferencia = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      ).difference(DateTime(fecha.year, fecha.month, fecha.day)).inDays;
      if (diferencia >= 0 && diferencia < 7) {
        neto[6 - diferencia] += movimiento.tipo == 'ingreso'
            ? movimiento.monto
            : -movimiento.monto;
      }
    }
    final netoSemana = neto.fold<double>(0, (suma, item) => suma + item);
    var acumulado = _saldo - netoSemana;
    final valores = <double>[acumulado];
    for (final item in neto) {
      acumulado += item;
      valores.add(acumulado);
    }
    return valores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : _errorCarga != null
          ? _error()
          : IndexedStack(
              index: _seccionActual,
              children: [_inicio(), _actividad(), _presupuesto(), _perfil()],
            ),
      floatingActionButton: _seccionActual < 2
          ? FloatingActionButton(
              heroTag: 'nuevo_movimiento',
              backgroundColor: _cyan,
              foregroundColor: _background,
              onPressed: _irAAgregar,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _seccionActual,
        onDestinationSelected: (indice) =>
            setState(() => _seccionActual = indice),
        backgroundColor: const Color(0xFF101A20),
        indicatorColor: _cyan.withValues(alpha: .17),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz_rounded),
            label: 'Actividad',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_small_outlined),
            selectedIcon: Icon(Icons.donut_small_rounded),
            label: 'Presupuesto',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _error() => Center(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: _glass(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: _cyan, size: 36),
            const SizedBox(height: 10),
            Text(_errorCarga!, style: const TextStyle(color: _text)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _cargarDatos,
              style: FilledButton.styleFrom(backgroundColor: _cyan),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _inicio() {
    final gastoTotal = _gastosPorCategoriaMes.values.fold<double>(
      0,
      (suma, item) => suma + item,
    );
    final ahorro = math.max(0.0, _ingresosMes - _gastosMes).toDouble();
    final fraccionPresupuesto = _limiteTotal == 0
        ? 0.0
        : (_gastosMes / _limiteTotal).clamp(0.0, 1.0).toDouble();

    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _surface,
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
        children: [
          _saludo(),
          const SizedBox(height: 15),
          _hero(),
          const SizedBox(height: 21),
          _tituloSeccion('Acciones rápidas'),
          const SizedBox(height: 9),
          _accionesRapidas(),
          const SizedBox(height: 21),
          _tituloSeccion('Salud financiera'),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _saludCard(
                  icono: Icons.pie_chart_outline_rounded,
                  titulo: 'Presupuesto',
                  valor: _limiteTotal == 0
                      ? '—'
                      : '${(fraccionPresupuesto * 100).round()}%',
                  detalle: _limiteTotal == 0
                      ? 'Sin límites definidos'
                      : '${_fmt(_gastosMes)} usado',
                  color: _emerald,
                  onTap: () => setState(() => _seccionActual = 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _saludCard(
                  icono: Icons.savings_outlined,
                  titulo: 'Ahorro del mes',
                  valor: _fmt(ahorro),
                  detalle: 'Ingresos menos gastos',
                  color: _violet,
                  onTap: _abrirMetasAhorro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          _tituloSeccion(
            'Gastos de ${_mesLegible(DateTime.now()).split(' ').first}',
          ),
          const SizedBox(height: 9),
          _distribucion(gastoTotal),
          if (_categoriasPrincipales.isNotEmpty) ...[
            const SizedBox(height: 21),
            _tituloSeccion('Categorías principales'),
            const SizedBox(height: 9),
            _categoriasDestacadas(gastoTotal),
          ],
          const SizedBox(height: 21),
          _tituloSeccion(
            'Movimientos recientes',
            accion: 'Ver todos',
            onTap: () => setState(() => _seccionActual = 1),
          ),
          const SizedBox(height: 9),
          _listaMovimientos(_movimientos.take(3).toList()),
        ],
      ),
    );
  }

  Widget _saludo() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buenas tardes',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 2),
            const Text(
              'Hola, Tomás',
              style: TextStyle(
                color: _text,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _detectorActivo
                      ? 'Detector automático activo'
                      : 'Detector automático inactivo',
                  style: TextStyle(
                    color: _detectorActivo ? const Color(0xFFA0E8D1) : _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _iconoCircular(
        Icons.notifications_none_rounded,
        _detectorActivo ? null : _activarDetector,
        'Notificaciones',
      ),
    ],
  );

  Widget _hero() => _glass(
    padding: const EdgeInsets.all(18),
    borderColor: _cyan.withValues(alpha: .25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Patrimonio disponible',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: _ocultarSaldo ? 'Mostrar saldo' : 'Ocultar saldo',
              onPressed: () => setState(() => _ocultarSaldo = !_ocultarSaldo),
              icon: Icon(
                _ocultarSaldo
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFFC5DEDB),
                size: 20,
              ),
            ),
          ],
        ),
        Text(
          _ocultarSaldo ? '••••••••' : _fmt(_saldo),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        Text(
          _mesLegible(DateTime.now()),
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 105,
          width: double.infinity,
          child: CustomPaint(painter: _BalanceTrendPainter(_tendenciaSemana())),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _miniMetrica('Ingresos', _fmt(_ingresosMes), _emerald),
            const SizedBox(width: 7),
            _miniMetrica('Gastos', _fmt(_gastosMes), _danger),
            const SizedBox(width: 7),
            _miniMetrica(
              'Ahorro',
              _fmt(math.max(0.0, _ingresosMes - _gastosMes).toDouble()),
              _violet,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _miniMetrica(String titulo, String valor, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: _muted, fontSize: 8)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _accionesRapidas() => Row(
    children: [
      Expanded(
        child: _accion(
          Icons.add_rounded,
          'Añadir gasto',
          () => _irAAgregar(tipoInicial: 'gasto'),
          color: _danger,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _accion(
          Icons.add_circle_outline_rounded,
          'Añadir ingreso',
          () => _irAAgregar(tipoInicial: 'ingreso'),
          color: _emerald,
        ),
      ),
    ],
  );

  Widget _accion(
    IconData icono,
    String texto,
    VoidCallback onTap, {
    Color color = _cyan,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .055),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icono, color: color, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC8DAD8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _saludCard({
    required IconData icono,
    required String titulo,
    required String valor,
    required String detalle,
    required Color color,
    VoidCallback? onTap,
  }) => _glass(
    padding: const EdgeInsets.all(13),
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 19),
            const Spacer(),
            Text(titulo, style: const TextStyle(color: _muted, fontSize: 9)),
            const SizedBox(height: 2),
            Text(
              valor,
              style: const TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              detalle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _distribucion(double total) {
    if (total == 0) {
      return _vacio(
        Icons.donut_small_outlined,
        'Aún no hay gastos este mes',
        'Registra movimientos para visualizar su distribución.',
      );
    }
    final colores = <Color>[_cyan, _emerald, _violet];
    final valores = _categoriasPrincipales.map((item) => item.value).toList();
    return _glass(
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(112),
                  painter: _SpendingRingPainter(valores, colores),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmt(total),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'GASTADO',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribución por categoría',
                  style: TextStyle(
                    color: _text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ..._categoriasPrincipales.asMap().entries.map((item) {
                  final indice = item.key;
                  final entrada = item.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colores[indice],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entrada.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBED2D0),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          '${(entrada.value / total * 100).round()}%',
                          style: const TextStyle(
                            color: _text,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriasDestacadas(double total) => Column(
    children: _categoriasPrincipales.take(2).map((entrada) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _glass(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _iconoCategoria(entrada.key),
                  color: _cyan,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entrada.key,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (entrada.value / total)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        minHeight: 6,
                        backgroundColor: const Color(0xFF294147),
                        valueColor: const AlwaysStoppedAnimation(_cyan),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _fmt(entrada.value),
                style: const TextStyle(
                  color: _text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );

  Widget _actividad() {
    final filtrados = _movimientos.where((item) {
      switch (_filtroActividad) {
        case 'Gastos':
          return item.tipo == 'gasto';
        case 'Ingresos':
          return item.tipo == 'ingreso';
        case 'Automáticos':
          return item.origen == 'automatico';
        default:
          return true;
      }
    }).toList();
    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _surface,
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
        children: [
          _cabecera('Actividad', 'Todo lo que entra y sale de tu dinero.'),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Gastos', 'Ingresos', 'Automáticos'].map((
                filtro,
              ) {
                final seleccionado = _filtroActividad == filtro;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filtro),
                    selected: seleccionado,
                    onSelected: (_) =>
                        setState(() => _filtroActividad = filtro),
                    selectedColor: _cyan.withValues(alpha: .18),
                    backgroundColor: Colors.white.withValues(alpha: .055),
                    side: BorderSide(
                      color: seleccionado
                          ? _cyan.withValues(alpha: .35)
                          : Colors.white.withValues(alpha: .1),
                    ),
                    labelStyle: TextStyle(
                      color: seleccionado ? const Color(0xFFB0FFF5) : _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_detectorActivo && _filtroActividad != 'Gastos') ...[
            const SizedBox(height: 15),
            _alertaDetector(),
          ],
          const SizedBox(height: 18),
          if (filtrados.isEmpty)
            _vacio(
              Icons.receipt_long_outlined,
              'No hay movimientos para mostrar',
              'Registra uno nuevo o cambia el filtro seleccionado.',
            )
          else
            _listaMovimientos(filtrados, mostrarOrigen: true),
        ],
      ),
    );
  }

  Widget _alertaDetector() => _glass(
    padding: const EdgeInsets.all(13),
    color: const Color(0xFF12332F),
    borderColor: _emerald.withValues(alpha: .25),
    child: Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 19),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detección automática lista',
                style: TextStyle(
                  color: _text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Las notificaciones compatibles aparecen en esta lista.',
                style: TextStyle(color: Color(0xFF9FC5BD), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _presupuesto() {
    final mes = _mesClave(DateTime.now());
    final gastosPorId = <int, double>{};
    for (final movimiento in _movimientos) {
      if (movimiento.tipo == 'gasto' && movimiento.fecha.startsWith(mes)) {
        gastosPorId.update(
          movimiento.categoriaId,
          (valor) => valor + movimiento.monto,
          ifAbsent: () => movimiento.monto,
        );
      }
    }
    for (final presupuesto in _presupuestos) {
      gastosPorId.putIfAbsent(presupuesto.categoriaId, () => 0);
    }
    final categorias = gastosPorId.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final limite = _limiteTotal;
    final disponible = math.max(0.0, limite - _gastosMes).toDouble();
    final avance = limite == 0
        ? 0.0
        : (_gastosMes / limite).clamp(0.0, 1.0).toDouble();
    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _surface,
      onRefresh: _cargarDatos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
        children: [
          _cabecera(
            'Presupuesto',
            '${_mesLegible(DateTime.now())} · avanza sin sorpresas.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _gestionarPresupuesto,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar presupuesto por categoría'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: BorderSide(color: _cyan.withValues(alpha: .5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            padding: const EdgeInsets.all(17),
            color: const Color(0xFF142A30),
            borderColor: _cyan.withValues(alpha: .25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disponible para gastar',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  limite == 0 ? 'Sin límite definido' : _fmt(disponible),
                  style: const TextStyle(
                    color: _text,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: avance,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF294349),
                    valueColor: const AlwaysStoppedAnimation(_cyan),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  limite == 0
                      ? 'Agrega límites por categoría para activar el control.'
                      : 'Has usado ${_fmt(_gastosMes)} de ${_fmt(limite)}.',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          _tituloSeccion('Gasto por categoría'),
          const SizedBox(height: 9),
          if (categorias.isEmpty)
            _vacio(
              Icons.account_balance_wallet_outlined,
              'Aún no hay gastos este mes',
              'Los gastos que agregues aparecerán organizados aquí.',
            )
          else
            _glass(
              padding: EdgeInsets.zero,
              child: Column(
                children: categorias.map((entrada) {
                  final categoria = _categoriasPorId[entrada.key];
                  Presupuesto? presupuesto;
                  for (final item in _presupuestos) {
                    if (item.categoriaId == entrada.key) {
                      presupuesto = item;
                      break;
                    }
                  }
                  final maximo = presupuesto?.montoLimite ?? _gastosMes;
                  final fraccion = maximo == 0
                      ? 0.0
                      : (entrada.value / maximo).clamp(0.0, 1.0).toDouble();
                  return InkWell(
                    onTap: () => _gestionarPresupuesto(presupuesto),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _cyan.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              _iconoCategoria(categoria?.nombre),
                              color: _cyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoria?.nombre ?? 'Sin categoría',
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  presupuesto == null
                                      ? '${_fmt(entrada.value)} gastado'
                                      : '${_fmt(entrada.value)} de ${_fmt(presupuesto.montoLimite)}',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: fraccion,
                                    minHeight: 5,
                                    backgroundColor: const Color(0xFF294147),
                                    valueColor: AlwaysStoppedAnimation(
                                      fraccion >= 1 ? _danger : _cyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(entrada.value),
                            style: const TextStyle(
                              color: _text,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 21),
          _tituloSeccion(
            'Metas de ahorro',
            accion: 'Gestionar',
            onTap: _abrirMetasAhorro,
          ),
          const SizedBox(height: 9),
          _glass(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF211E3A),
            borderColor: _violet.withValues(alpha: .25),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _violet.withValues(alpha: .17),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFFC8C1FF),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ahorro disponible este mes',
                        style: TextStyle(
                          color: _text,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _fmt(
                          math.max(0.0, _ingresosMes - _gastosMes).toDouble(),
                        ),
                        style: const TextStyle(
                          color: Color(0xFFC8C1FF),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Gestionar metas de ahorro',
                  onPressed: _abrirMetasAhorro,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFC8C1FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfil() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
    children: [
      _cabecera('Perfil', 'Tu espacio personal.'),
      const SizedBox(height: 16),
      _glass(
        padding: const EdgeInsets.all(19),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _cyan.withValues(alpha: .40),
                  width: 2,
                ),
              ),
              child: const Text(
                'T',
                style: TextStyle(
                  color: Color(0xFF9EFFF4),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Tomás García',
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Control de finanzas personales',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _detectorActivo
                        ? 'Automatización activada'
                        : 'Automatización pendiente',
                    style: const TextStyle(
                      color: Color(0xFFB2FFF4),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 21),
      _tituloSeccion('Configuración'),
      const SizedBox(height: 9),
      _opciones([
        _Opcion(
          Icons.notifications_active_outlined,
          'Detección automática',
          _detectorActivo
              ? 'Notificaciones bancarias autorizadas'
              : 'Actívala para registrar movimientos',
          _activarDetector,
        ),
        _Opcion(
          Icons.category_outlined,
          'Categorías',
          '${_categoriasPorId.length} categorías disponibles',
          _mostrarCategorias,
        ),
        _Opcion(
          Icons.calendar_month_outlined,
          'Periodo de resumen',
          _mesLegible(DateTime.now()),
          () => _mensaje('El resumen usa el mes en curso.'),
        ),
      ]),
      const SizedBox(height: 21),
      _tituloSeccion('Modo pruebas'),
      const SizedBox(height: 9),
      _opciones([
        _Opcion(
          Icons.restart_alt_rounded,
          'Reiniciar datos',
          'Borra movimientos, presupuestos y metas',
          _reiniciarDatosPrueba,
        ),
      ]),
      const SizedBox(height: 21),
      _tituloSeccion('Información'),
      const SizedBox(height: 9),
      _opciones([
        _Opcion(
          Icons.privacy_tip_outlined,
          'Privacidad y seguridad',
          'La información se almacena en el dispositivo',
          () => _mensaje('Tus movimientos se guardan de forma local.'),
        ),
        _Opcion(
          Icons.info_outline_rounded,
          'Acerca de Finanzas App',
          'Versión de demostración',
          () => _mensaje('Finanzas App · Proyecto Capstone'),
        ),
      ]),
    ],
  );

  Future<void> _mostrarCategorias() async {
    await _abrirCategorias();
  }

  Widget _opciones(List<_Opcion> opciones) => _glass(
    padding: EdgeInsets.zero,
    child: Column(
      children: opciones.asMap().entries.map((entrada) {
        final ultima = entrada.key == opciones.length - 1;
        final opcion = entrada.value;
        return Column(
          children: [
            ListTile(
              onTap: opcion.onTap,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(opcion.icono, color: _cyan, size: 18),
              ),
              title: Text(
                opcion.titulo,
                style: const TextStyle(
                  color: _text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                opcion.detalle,
                style: const TextStyle(color: _muted, fontSize: 9),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
            ),
            if (!ultima)
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: .08),
                indent: 16,
                endIndent: 16,
              ),
          ],
        );
      }).toList(),
    ),
  );

  Widget _cabecera(String titulo, String subtitulo) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: _text,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
      _iconoCircular(
        Icons.search_rounded,
        () => _mensaje('La búsqueda estará disponible próximamente.'),
        'Buscar',
      ),
    ],
  );

  Widget _iconoCircular(IconData icono, VoidCallback? onTap, String tooltip) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(icono, color: const Color(0xFFD8F0ED), size: 20),
        ),
      );

  Widget _tituloSeccion(String titulo, {String? accion, VoidCallback? onTap}) =>
      Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (accion != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: _cyan,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                accion,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      );

  Widget _listaMovimientos(
    List<Transaccion> movimientos, {
    bool mostrarOrigen = false,
  }) {
    if (movimientos.isEmpty) {
      return _vacio(
        Icons.receipt_long_outlined,
        'Aún no hay movimientos',
        'Registra un gasto o ingreso para comenzar.',
      );
    }
    return _glass(
      padding: EdgeInsets.zero,
      child: Column(
        children: movimientos.asMap().entries.map((entrada) {
          final index = entrada.key;
          final item = entrada.value;
          final categoria = _categoriasPorId[item.categoriaId];
          final gasto = item.tipo == 'gasto';
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _verDetalle(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (gasto ? _cyan : _violet).withValues(
                              alpha: .13,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.origen == 'automatico'
                                ? Icons.account_balance_outlined
                                : _iconoCategoria(categoria?.nombre),
                            color: gasto ? _cyan : _violet,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoria?.nombre ?? 'Sin categoría',
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mostrarOrigen && item.origen == 'automatico'
                                    ? '${item.institucion ?? 'Movimiento automático'} · Importado'
                                    : (item.descripcion.isEmpty
                                          ? item.fecha
                                          : item.descripcion),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${gasto ? '-' : '+'}${_fmt(item.monto)}',
                          style: TextStyle(
                            color: gasto ? _danger : _emerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (index != movimientos.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: .08),
                  indent: 58,
                  endIndent: 13,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _vacio(IconData icono, String titulo, String detalle) => _glass(
    padding: const EdgeInsets.all(22),
    child: Column(
      children: [
        Icon(icono, color: _cyan, size: 31),
        const SizedBox(height: 9),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detalle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    Color? color,
    Color? borderColor,
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? _surface.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: .10),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class _Opcion {
  const _Opcion(this.icono, this.titulo, this.detalle, this.onTap);

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
}

class _DatosPresupuesto {
  const _DatosPresupuesto({
    required this.categoriaId,
    required this.montoLimite,
  }) : eliminar = false;

  const _DatosPresupuesto.eliminar()
    : categoriaId = 0,
      montoLimite = 0,
      eliminar = true;

  final int categoriaId;
  final double montoLimite;
  final bool eliminar;
}

class _BalanceTrendPainter extends CustomPainter {
  const _BalanceTrendPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 8.0;
    const bottom = 15.0;
    final height = size.height - top - bottom;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 1 ? 1.0 : maxValue - minValue;
    final guide = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      canvas.drawLine(
        Offset(0, top + height * index / 2),
        Offset(size.width, top + height * index / 2),
        guide,
      );
    }
    final puntos = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = top + height * (1 - (values[index] - minValue) / range);
      puntos.add(Offset(x, y));
    }
    final linea = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (var index = 1; index < puntos.length; index++) {
      linea.lineTo(puntos[index].dx, puntos[index].dy);
    }
    final area = Path.from(linea)
      ..lineTo(puntos.last.dx, top + height)
      ..lineTo(puntos.first.dx, top + height)
      ..close();
    canvas.drawPath(area, Paint()..color = const Color(0x2631D9D0));
    canvas.drawPath(
      linea,
      Paint()
        ..color = const Color(0xFF31D9D0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(puntos.last, 6, Paint()..color = const Color(0xFF0B1014));
    canvas.drawCircle(puntos.last, 4, Paint()..color = const Color(0xFF8EFFF4));
  }

  @override
  bool shouldRepaint(covariant _BalanceTrendPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _SpendingRingPainter extends CustomPainter {
  const _SpendingRingPainter(this.values, this.colors);

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 9;
    const stroke = 12.0;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF294147)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final total = values.fold<double>(0, (suma, item) => suma + item);
    if (total == 0) return;
    var inicio = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final fraccion = values[index] / total;
      final barrido = math.max(.04, fraccion * math.pi * 2 - .06);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        inicio,
        barrido,
        false,
        Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      inicio += fraccion * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingRingPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}
