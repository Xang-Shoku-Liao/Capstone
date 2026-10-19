import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/categoria.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const _background = Color(0xFF0B1014);
  static const _surface = Color(0xFF141F26);
  static const _cyan = Color(0xFF31D9D0);
  static const _emerald = Color(0xFF42D392);
  static const _text = Color(0xFFF2FFFC);
  static const _muted = Color(0xFF8EA2A5);

  final _db = DatabaseHelper.instance;
  List<Categoria> _categorias = [];
  bool _cargando = true;
  String _tipo = 'gasto';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final categorias = await _db.getCategorias(tipo: _tipo);
    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      _cargando = false;
    });
  }

  Future<void> _agregarCategoria() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _tipo == 'gasto'
              ? 'Nueva categoría de gasto'
              : 'Nueva categoría de ingreso',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ej: Mascotas, Salud, Freelance',
          ),
          onSubmitted: (valor) => Navigator.pop(context, valor.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (nombre == null || nombre.isEmpty) return;
    final existe = _categorias.any(
      (categoria) => categoria.nombre.toLowerCase() == nombre.toLowerCase(),
    );
    if (existe) {
      _mensaje('Ya existe una categoría con ese nombre.');
      return;
    }
    await _db.insertCategoria(Categoria(nombre: nombre, tipo: _tipo));
    await _cargar();
    if (mounted) _mensaje('Categoría "$nombre" creada.');
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    if (categoria.id == null) return;
    final estaEnUso = await _db.categoriaEstaEnUso(categoria.id!);
    if (!mounted) return;
    if (estaEnUso) {
      _mensaje(
        'No puedes eliminarla porque tiene movimientos o un presupuesto asociado.',
      );
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Eliminarás "${categoria.nombre}". Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _db.deleteCategoria(categoria.id!);
    await _cargar();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(texto)),
    );
  }

  IconData _icono(String nombre) {
    final texto = nombre.toLowerCase();
    if (texto.contains('comida') ||
        texto.contains('aliment') ||
        texto.contains('super')) {
      return Icons.shopping_basket_outlined;
    }
    if (texto.contains('transporte') || texto.contains('movilidad')) {
      return Icons.directions_bus_outlined;
    }
    if (texto.contains('salud')) {
      return Icons.favorite_border_rounded;
    }
    if (texto.contains('ocio') || texto.contains('entreten')) {
      return Icons.movie_outlined;
    }
    if (texto.contains('sueldo') || texto.contains('trabajo')) {
      return Icons.payments_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = _tipo == 'gasto' ? _cyan : _emerald;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarCategoria,
        backgroundColor: color,
        foregroundColor: _background,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : RefreshIndicator(
              color: _cyan,
              backgroundColor: _surface,
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
                  const Text(
                    'Organiza tus movimientos',
                    style: TextStyle(
                      color: _text,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Crea categorías para que tus gastos e ingresos sean fáciles de identificar.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      _selector('Gastos', 'gasto', _cyan),
                      const SizedBox(width: 9),
                      _selector('Ingresos', 'ingreso', _emerald),
                    ],
                  ),
                  const SizedBox(height: 17),
                  if (_categorias.isEmpty)
                    _vacio()
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF23343B)),
                      ),
                      child: Column(
                        children: _categorias.asMap().entries.map((entrada) {
                          final index = entrada.key;
                          final categoria = entrada.value;
                          return Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _icono(categoria.nombre),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  categoria.nombre,
                                  style: const TextStyle(
                                    color: _text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  _tipo == 'gasto'
                                      ? 'Categoría de gasto'
                                      : 'Categoría de ingreso',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Eliminar categoría',
                                  onPressed: () =>
                                      _eliminarCategoria(categoria),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              if (index < _categorias.length - 1)
                                const Divider(
                                  height: 1,
                                  color: Color(0xFF23343B),
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _selector(String texto, String valor, Color color) {
    final seleccionado = _tipo == valor;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          if (seleccionado) return;
          setState(() {
            _tipo = valor;
            _cargando = true;
          });
          _cargar();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: seleccionado
              ? color.withValues(alpha: .16)
              : _surface,
          foregroundColor: seleccionado ? color : _muted,
          side: BorderSide(
            color: seleccionado
                ? color.withValues(alpha: .55)
                : const Color(0xFF23343B),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _vacio() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF23343B)),
    ),
    child: const Column(
      children: [
        Icon(Icons.category_outlined, color: _cyan, size: 32),
        SizedBox(height: 9),
        Text(
          'No hay categorías todavía',
          style: TextStyle(color: _text, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          'Usa “Agregar” para crear la primera.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}
