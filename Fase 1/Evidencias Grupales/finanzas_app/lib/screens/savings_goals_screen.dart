import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/meta_ahorro.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  static const _background = Color(0xFF0B1014);
  static const _surface = Color(0xFF141F26);
  static const _violet = Color(0xFF8B7CFF);
  static const _emerald = Color(0xFF42D392);
  static const _text = Color(0xFFF2FFFC);
  static const _muted = Color(0xFF8EA2A5);

  final _db = DatabaseHelper.instance;
  List<MetaAhorro> _metas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final metas = await _db.getMetasAhorro();
    if (!mounted) return;
    setState(() {
      _metas = metas;
      _cargando = false;
    });
  }

  double? _monto(String texto) {
    final limpio = texto
        .trim()
        .replaceAll(r'$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(limpio);
  }

  String _fechaActual() {
    final hoy = DateTime.now();
    return '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  }

  Future<void> _editarMeta([MetaAhorro? meta]) async {
    final nombre = TextEditingController(text: meta?.nombre ?? '');
    final objetivo = TextEditingController(
      text: meta == null ? '' : meta.montoObjetivo.round().toString(),
    );
    final actual = TextEditingController(
      text: meta == null || meta.montoActual == 0
          ? ''
          : meta.montoActual.round().toString(),
    );
    String? error;
    final resultado = await showDialog<MetaAhorro>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) => AlertDialog(
          title: Text(meta == null ? 'Nueva meta de ahorro' : 'Editar meta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombre,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    hintText: 'Ej: Viaje, notebook, emergencia',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: objetivo,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    prefixText: r'$ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: actual,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto ahorrado hasta hoy',
                    prefixText: r'$ ',
                    hintText: '0',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFFF8F87),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final montoObjetivo = _monto(objetivo.text);
                final montoActual = actual.text.trim().isEmpty
                    ? 0.0
                    : _monto(actual.text);
                if (nombre.text.trim().isEmpty ||
                    montoObjetivo == null ||
                    montoObjetivo <= 0 ||
                    montoActual == null ||
                    montoActual < 0) {
                  actualizar(
                    () => error = 'Completa un nombre y montos válidos.',
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  MetaAhorro(
                    id: meta?.id,
                    nombre: nombre.text.trim(),
                    montoObjetivo: montoObjetivo,
                    montoActual: montoActual,
                    fechaCreacion: meta?.fechaCreacion ?? _fechaActual(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                foregroundColor: Colors.white,
              ),
              child: Text(meta == null ? 'Crear meta' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
    // El cierre de un diálogo termina antes de que su árbol de TextField se
    // desmonte por completo. Esperar al siguiente frame evita una aserción de
    // Flutter al liberar los controladores.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nombre.dispose();
      objetivo.dispose();
      actual.dispose();
    });
    if (resultado == null) return;
    if (meta == null) {
      await _db.insertMetaAhorro(resultado);
    } else {
      await _db.updateMetaAhorro(resultado);
    }
    await _cargar();
  }

  Future<void> _eliminar(MetaAhorro meta) async {
    if (meta.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar meta?'),
        content: Text('Eliminarás la meta "${meta.nombre}".'),
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
    await _db.deleteMetaAhorro(meta.id!);
    await _cargar();
  }

  String _fmt(double monto) {
    final texto = monto.round().abs().toString();
    final salida = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) salida.write('.');
      salida.write(texto[i]);
    }
    return r'$' + salida.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Metas de ahorro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editarMeta,
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva meta'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _violet))
          : RefreshIndicator(
              color: _violet,
              backgroundColor: _surface,
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
                  const Text(
                    'Ahorra con un propósito',
                    style: TextStyle(
                      color: _text,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Define una meta y actualiza tu avance cuando guardes dinero.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 17),
                  if (_metas.isEmpty) _vacio() else ..._metas.map(_tarjetaMeta),
                ],
              ),
            ),
    );
  }

  Widget _tarjetaMeta(MetaAhorro meta) {
    final progreso = (meta.montoActual / meta.montoObjetivo)
        .clamp(0.0, 1.0)
        .toDouble();
    final completada = progreso >= 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editarMeta(meta),
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: _violet.withValues(alpha: .28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: _violet.withValues(alpha: .17),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        completada
                            ? Icons.verified_rounded
                            : Icons.savings_outlined,
                        color: completedColor(completada),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        meta.nombre,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar meta',
                      onPressed: () => _eliminar(meta),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 9,
                    backgroundColor: const Color(0xFF29333E),
                    valueColor: AlwaysStoppedAnimation(
                      completedColor(completada),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _dato('Llevas', _fmt(meta.montoActual), _emerald),
                    ),
                    Expanded(
                      child: _dato(
                        completada ? 'Completada' : 'Te falta',
                        completada
                            ? '¡Meta lograda!'
                            : _fmt(meta.montoFaltante),
                        completedColor(completada),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${(progreso * 100).round()}% de ${_fmt(meta.montoObjetivo)} · Toca para actualizar',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color completedColor(bool completada) => completada ? _emerald : _violet;

  Widget _dato(String etiqueta, String valor, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: const TextStyle(color: _muted, fontSize: 10)),
      const SizedBox(height: 2),
      Text(
        valor,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _vacio() => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFF2E2A4D)),
    ),
    child: const Column(
      children: [
        Icon(Icons.flag_outlined, color: _violet, size: 34),
        SizedBox(height: 10),
        Text(
          'Todavía no tienes metas',
          style: TextStyle(color: _text, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          'Crea una para visualizar tu avance y cuánto te falta.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}
