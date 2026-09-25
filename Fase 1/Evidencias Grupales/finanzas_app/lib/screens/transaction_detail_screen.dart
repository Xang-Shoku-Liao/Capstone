import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transaccion,
    this.categoriaInicial,
  });

  final Transaccion transaccion;
  final Categoria? categoriaInicial;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _db = DatabaseHelper.instance;
  late Transaccion _transaccion;
  Categoria? _categoria;
  List<Categoria> _categorias = [];
  bool _cargandoCategorias = true;

  static const _teal = Color(0xFF028090);
  static const _ingreso = Color(0xFF1D9E75);
  static const _gasto = Color(0xFFC4472A);

  @override
  void initState() {
    super.initState();
    _transaccion = widget.transaccion;
    _categoria = widget.categoriaInicial;
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final categorias = await _db.getCategorias(tipo: _transaccion.tipo);
    if (!mounted) return;
    Categoria? categoriaSeleccionada = widget.categoriaInicial;
    for (final categoria in categorias) {
      if (categoria.id == _transaccion.categoriaId) {
        categoriaSeleccionada = categoria;
        break;
      }
    }
    setState(() {
      _categorias = categorias;
      _categoria = categoriaSeleccionada;
      _cargandoCategorias = false;
    });
  }

  Future<void> _editarCategoria() async {
    if (_cargandoCategorias || _transaccion.id == null) return;
    final categoriaElegida = await showModalBottomSheet<Categoria>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Text(
                'Cambiar categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._categorias.map(
              (categoria) => ListTile(
                leading: Icon(
                  categoria.id == _transaccion.categoriaId
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: categoria.id == _transaccion.categoriaId
                      ? _teal
                      : Colors.grey,
                ),
                title: Text(categoria.nombre),
                onTap: () => Navigator.pop(context, categoria),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (categoriaElegida == null ||
        categoriaElegida.id == _transaccion.categoriaId) {
      return;
    }

    await _db.updateCategoriaTransaccion(
      _transaccion.id!,
      categoriaElegida.id!,
    );
    if (!mounted) return;
    setState(() {
      _transaccion = _transaccion.copyWith(categoriaId: categoriaElegida.id);
      _categoria = categoriaElegida;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Categoría cambiada a ${categoriaElegida.nombre}'),
      ),
    );
  }

  Future<void> _eliminar() async {
    if (_transaccion.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _gasto),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    await _db.deleteTransaccion(_transaccion.id!);
    if (mounted) Navigator.pop(context, true);
  }

  String _montoFormateado(double monto) {
    final entero = monto.round();
    final texto = entero.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < texto.length; index++) {
      if (index > 0 && (texto.length - index) % 3 == 0) buffer.write('.');
      buffer.write(texto[index]);
    }
    return '\$$buffer';
  }

  String _fechaLegible(String fecha) {
    final partes = fecha.split('-');
    if (partes.length != 3) return fecha;
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final mes = int.tryParse(partes[1]);
    if (mes == null || mes < 1 || mes > 12) return fecha;
    return '${int.tryParse(partes[2]) ?? partes[2]} de ${meses[mes - 1]} de ${partes[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final esGasto = _transaccion.tipo == 'gasto';
    final color = esGasto ? _gasto : _ingreso;
    final tipoTexto = esGasto ? 'Gasto' : 'Ingreso';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del movimiento'),
        backgroundColor: const Color(0xFF013A40),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Eliminar movimiento',
            onPressed: _eliminar,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  esGasto ? Icons.south_east_rounded : Icons.north_east_rounded,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '${esGasto ? '-' : '+'}${_montoFormateado(_transaccion.monto)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_transaccion.estado[0].toUpperCase()}${_transaccion.estado.substring(1)} · $tipoTexto',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _seccion('Información'),
          _fila(
            icono: Icons.category_outlined,
            titulo: 'Categoría',
            valor: _categoria?.nombre ?? 'Sin categoría',
            accion: _cargandoCategorias ? null : _editarCategoria,
            textoAccion: 'Editar',
          ),
          _fila(
            icono: Icons.calendar_today_outlined,
            titulo: 'Fecha',
            valor: _fechaLegible(_transaccion.fecha),
          ),
          if (_transaccion.hora != null)
            _fila(
              icono: Icons.access_time_outlined,
              titulo: 'Hora de detección',
              valor: _transaccion.hora!,
            ),
          if (_transaccion.descripcion.isNotEmpty)
            _fila(
              icono: Icons.notes_outlined,
              titulo: 'Descripción',
              valor: _transaccion.descripcion,
            ),
          const SizedBox(height: 20),
          _seccion('Registro'),
          _fila(
            icono: _transaccion.origen == 'automatico'
                ? Icons.auto_awesome_outlined
                : Icons.edit_outlined,
            titulo: 'Origen',
            valor: _transaccion.origen == 'automatico'
                ? 'Detectado automáticamente'
                : 'Ingresado manualmente',
          ),
          if (_transaccion.institucion != null)
            _fila(
              icono: Icons.account_balance_outlined,
              titulo: 'Fuente',
              valor: _transaccion.institucion!,
            ),
        ],
      ),
    );
  }

  Widget _seccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          color: _teal,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _fila({
    required IconData icono,
    required String titulo,
    required String valor,
    VoidCallback? accion,
    String? textoAccion,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1DA)),
      ),
      child: ListTile(
        leading: Icon(icono, color: _teal),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          valor,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        trailing: accion == null
            ? null
            : TextButton(
                onPressed: accion,
                child: Text(textoAccion ?? 'Cambiar'),
              ),
      ),
    );
  }
}
