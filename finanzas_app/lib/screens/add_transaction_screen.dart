import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _db = DatabaseHelper.instance;
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _tipo = 'gasto';
  DateTime _fecha = DateTime.now();
  List<Categoria> _categorias = [];
  int? _categoriaIdSeleccionada;
  bool _guardando = false;

  static const Color teal = Color(0xFF028090);
  static const Color seafoam = Color(0xFF00A896);
  static const Color success = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias({int? seleccionarId}) async {
    final tipoSolicitado = _tipo;
    final categorias = await _db.getCategorias(tipo: tipoSolicitado);
    if (!mounted || tipoSolicitado != _tipo) return;
    setState(() {
      _categorias = categorias;
      if (seleccionarId != null &&
          categorias.any((c) => c.id == seleccionarId)) {
        _categoriaIdSeleccionada = seleccionarId;
      } else {
        _categoriaIdSeleccionada = categorias.isNotEmpty
            ? categorias.first.id
            : null;
      }
    });
  }

  void _cambiarTipo(String tipo) {
    setState(() => _tipo = tipo);
    _cargarCategorias();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
    }
  }

  String get _fechaIso {
    return '${_fecha.year.toString().padLeft(4, '0')}-'
        '${_fecha.month.toString().padLeft(2, '0')}-'
        '${_fecha.day.toString().padLeft(2, '0')}';
  }

  void _manejarSeleccionCategoria(int? valor) {
    setState(() => _categoriaIdSeleccionada = valor);
  }

  Future<void> _mostrarDialogoNuevaCategoria() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ej: Mascotas, Salud, Arriendo...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (nombre == null || nombre.isEmpty) {
      controller.dispose();
      return;
    }

    try {
      final nuevaCategoria = Categoria(nombre: nombre, tipo: _tipo);
      final nuevoId = await _db.insertCategoria(nuevaCategoria);
      if (!mounted) return;
      await _cargarCategorias(seleccionarId: nuevoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoría "$nombre" creada y seleccionada')),
      );
    } catch (_) {
      if (mounted) {
        _mostrarError('No se pudo crear la categoría. Intenta nuevamente.');
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _guardar() async {
    final montoTexto = _montoController.text.trim();
    final monto = double.tryParse(montoTexto);

    if (monto == null || monto <= 0) {
      _mostrarError('Ingresa un monto válido');
      return;
    }
    if (_categoriaIdSeleccionada == null) {
      _mostrarError('Selecciona una categoría');
      return;
    }

    setState(() => _guardando = true);

    final transaccion = Transaccion(
      categoriaId: _categoriaIdSeleccionada!,
      monto: monto,
      fecha: _fechaIso,
      descripcion: _descripcionController.text.trim(),
      tipo: _tipo,
      origen: 'manual',
      estado: 'confirmado',
    );

    try {
      await _db.insertTransaccion(transaccion);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _guardando = false);
        _mostrarError('No se pudo guardar el movimiento. Intenta nuevamente.');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo movimiento'),
        backgroundColor: const Color(0xFF013A40),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _tipoBoton('Gasto', 'gasto', teal)),
                const SizedBox(width: 8),
                Expanded(child: _tipoBoton('Ingreso', 'ingreso', success)),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Monto',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Categoría',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(_categoriaIdSeleccionada),
                    initialValue: _categoriaIdSeleccionada,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1EFE8),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: _categorias
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: _manejarSeleccionCategoria,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _mostrarDialogoNuevaCategoria,
                  icon: const Icon(Icons.add_circle, color: teal),
                  tooltip: 'Agregar nueva categoría',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Fecha',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: _elegirFecha,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_fechaIso),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Descripción (opcional)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF1EFE8),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: seafoam,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar movimiento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoBoton(String label, String valor, Color colorActivo) {
    final activo = _tipo == valor;
    return OutlinedButton(
      onPressed: () => _cambiarTipo(valor),
      style: OutlinedButton.styleFrom(
        backgroundColor: activo ? colorActivo : const Color(0xFFF1EFE8),
        foregroundColor: activo ? Colors.white : Colors.black87,
        side: BorderSide(color: activo ? colorActivo : const Color(0xFFE1E1DA)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
