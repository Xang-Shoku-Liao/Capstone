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
  Categoria? _categoriaSeleccionada;
  bool _guardando = false;

  static const Color teal = Color(0xFF028090);
  static const Color seafoam = Color(0xFF00A896);
  static const Color success = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final categorias = await _db.getCategorias(tipo: _tipo);
    setState(() {
      _categorias = categorias;
      _categoriaSeleccionada = categorias.isNotEmpty ? categorias.first : null;
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

  Future<void> _guardar() async {
    final montoTexto = _montoController.text.trim();
    final monto = double.tryParse(montoTexto);

    if (monto == null || monto <= 0) {
      _mostrarError('Ingresa un monto válido');
      return;
    }
    if (_categoriaSeleccionada == null) {
      _mostrarError('Selecciona una categoría');
      return;
    }

    setState(() => _guardando = true);

    final transaccion = Transaccion(
      categoriaId: _categoriaSeleccionada!.id!,
      monto: monto,
      fecha: _fechaIso,
      descripcion: _descripcionController.text.trim(),
      tipo: _tipo,
      origen: 'manual',
      estado: 'confirmado',
    );

    await _db.insertTransaccion(transaccion);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
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
                Expanded(
                  child: _tipoBoton('Gasto', 'gasto', teal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tipoBoton('Ingreso', 'ingreso', success),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Monto',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            const Text('Categoría',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            DropdownButtonFormField<Categoria>(
              value: _categoriaSeleccionada,
              isExpanded: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF1EFE8),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.nombre),
                      ))
                  .toList(),
              onChanged: (c) => setState(() => _categoriaSeleccionada = c),
            ),
            const SizedBox(height: 16),
            const Text('Fecha',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            InkWell(
              onTap: _elegirFecha,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_fechaIso),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Descripción (opcional)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF1EFE8),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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
