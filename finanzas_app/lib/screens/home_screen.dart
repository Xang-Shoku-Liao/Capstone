import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  double _ingresos = 0;
  double _gastos = 0;
  Map<String, double> _gastosPorCategoria = {};
  List<Transaccion> _ultimosMovimientos = [];
  Map<int, Categoria> _categoriasPorId = {};
  bool _cargando = true;

  static const Color darkTeal = Color(0xFF013A40);
  static const Color teal = Color(0xFF028090);
  static const Color seafoam = Color(0xFF00A896);
  static const Color mint = Color(0xFF02C39A);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final categorias = await _db.getCategorias();
    final ingresos = await _db.getTotalPorTipo('ingreso');
    final gastos = await _db.getTotalPorTipo('gasto');
    final gastosPorCat = await _db.getGastosPorCategoria();
    final ultimos = await _db.getTransacciones(limite: 10);

    setState(() {
      _categoriasPorId = {for (final c in categorias) c.id!: c};
      _ingresos = ingresos;
      _gastos = gastos;
      _gastosPorCategoria = gastosPorCat;
      _ultimosMovimientos = ultimos;
      _cargando = false;
    });
  }

  String _fmt(double n) {
    final entero = n.round();
    final str = entero.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${entero < 0 ? '-' : ''}\$$buffer';
  }

  Future<void> _irAAgregar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (resultado == true) {
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldo = _ingresos - _gastos;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(saldo)),
                  SliverToBoxAdapter(child: _buildCategorias()),
                  SliverToBoxAdapter(child: _buildMovimientos()),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: seafoam,
        onPressed: _irAAgregar,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(double saldo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: darkTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis finanzas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: teal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saldo disponible',
                    style: TextStyle(color: mint, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _fmt(saldo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _dot(mint),
                    const SizedBox(width: 4),
                    Text('Ingresos: ${_fmt(_ingresos)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 18),
                    _dot(const Color(0xFFFF9E80)),
                    const SizedBox(width: 4),
                    Text('Gastos: ${_fmt(_gastos)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildCategorias() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gastos por categoría',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E1DA)),
            ),
            child: _gastosPorCategoria.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('Aún no hay gastos registrados.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  )
                : Column(
                    children: _gastosPorCategoria.entries.map((e) {
                      final maxVal = _gastosPorCategoria.values
                          .reduce((a, b) => a > b ? a : b);
                      final frac = maxVal > 0 ? e.value / maxVal : 0.0;
                      final pct =
                          _gastos > 0 ? (e.value / _gastos * 100).round() : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 78,
                                child: Text(e.key,
                                    style: const TextStyle(fontSize: 12))),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: frac,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE6E6E0),
                                  valueColor:
                                      const AlwaysStoppedAnimation(teal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                                width: 34,
                                child: Text('$pct%',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Últimos movimientos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E1DA)),
            ),
            child: _ultimosMovimientos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Aún no has agregado movimientos.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  )
                : Column(
                    children: _ultimosMovimientos.map((t) {
                      final cat = _categoriasPorId[t.categoriaId];
                      final esGasto = t.tipo == 'gasto';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat?.nombre ?? '—',
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600)),
                                if (t.descripcion.isNotEmpty)
                                  Text(t.descripcion,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            Text(
                              '${esGasto ? '-' : '+'}${_fmt(t.monto)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: esGasto
                                    ? const Color(0xFFC4472A)
                                    : const Color(0xFF1D9E75),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
