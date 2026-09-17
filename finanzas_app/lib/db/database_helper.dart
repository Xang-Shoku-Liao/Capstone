import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';
import '../models/transaccion.dart';
import '../models/presupuesto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finanzas.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaccion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        descripcion TEXT,
        tipo TEXT NOT NULL,
        origen TEXT NOT NULL DEFAULT 'manual',
        estado TEXT NOT NULL DEFAULT 'confirmado',
        FOREIGN KEY (categoria_id) REFERENCES categoria (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE presupuesto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria_id INTEGER NOT NULL,
        monto_limite REAL NOT NULL,
        mes TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categoria (id)
      )
    ''');

    // Categorías por defecto, para no partir con la app vacía
    final categoriasIniciales = [
      {'nombre': 'Comida', 'tipo': 'gasto'},
      {'nombre': 'Transporte', 'tipo': 'gasto'},
      {'nombre': 'Ocio', 'tipo': 'gasto'},
      {'nombre': 'Servicios', 'tipo': 'gasto'},
      {'nombre': 'Otro', 'tipo': 'gasto'},
      {'nombre': 'Sueldo', 'tipo': 'ingreso'},
      {'nombre': 'Otro ingreso', 'tipo': 'ingreso'},
    ];
    for (final c in categoriasIniciales) {
      await db.insert('categoria', c);
    }
  }

  // ---------------- Categoria ----------------

  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categoria', categoria.toMap());
  }

  Future<List<Categoria>> getCategorias({String? tipo}) async {
    final db = await database;
    final maps = tipo == null
        ? await db.query('categoria', orderBy: 'nombre')
        : await db.query('categoria',
            where: 'tipo = ?', whereArgs: [tipo], orderBy: 'nombre');
    return maps.map((m) => Categoria.fromMap(m)).toList();
  }

  // ---------------- Transaccion ----------------

  Future<int> insertTransaccion(Transaccion t) async {
    final db = await database;
    return await db.insert('transaccion', t.toMap());
  }

  Future<List<Transaccion>> getTransacciones({int? limite}) async {
    final db = await database;
    final maps = await db.query(
      'transaccion',
      orderBy: 'fecha DESC, id DESC',
      limit: limite,
    );
    return maps.map((m) => Transaccion.fromMap(m)).toList();
  }

  Future<List<Transaccion>> getTransaccionesPorMes(String mes) async {
    // mes en formato 'yyyy-MM'
    final db = await database;
    final maps = await db.query(
      'transaccion',
      where: "fecha LIKE ?",
      whereArgs: ['$mes%'],
      orderBy: 'fecha DESC, id DESC',
    );
    return maps.map((m) => Transaccion.fromMap(m)).toList();
  }

  Future<int> deleteTransaccion(int id) async {
    final db = await database;
    return await db.delete('transaccion', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalPorTipo(String tipo, {String? mes}) async {
    final db = await database;
    final where = mes != null ? "tipo = ? AND fecha LIKE ?" : "tipo = ?";
    final whereArgs = mes != null ? [tipo, '$mes%'] : [tipo];
    final result = await db.rawQuery(
      'SELECT SUM(monto) as total FROM transaccion WHERE $where',
      whereArgs,
    );
    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  /// Devuelve un mapa {nombre_categoria: total_gastado} para el mes indicado
  /// (o para todos los tiempos si mes es null). Solo considera gastos.
  Future<Map<String, double>> getGastosPorCategoria({String? mes}) async {
    final db = await database;
    final where = mes != null
        ? "t.tipo = 'gasto' AND t.fecha LIKE ?"
        : "t.tipo = 'gasto'";
    final whereArgs = mes != null ? ['$mes%'] : <String>[];

    final result = await db.rawQuery('''
      SELECT c.nombre as nombre, SUM(t.monto) as total
      FROM transaccion t
      INNER JOIN categoria c ON c.id = t.categoria_id
      WHERE $where
      GROUP BY c.nombre
      ORDER BY total DESC
    ''', whereArgs);

    final Map<String, double> out = {};
    for (final row in result) {
      out[row['nombre'] as String] = (row['total'] as num).toDouble();
    }
    return out;
  }

  // ---------------- Presupuesto ----------------

  Future<int> insertOrUpdatePresupuesto(Presupuesto p) async {
    final db = await database;
    final existentes = await db.query(
      'presupuesto',
      where: 'categoria_id = ? AND mes = ?',
      whereArgs: [p.categoriaId, p.mes],
    );
    if (existentes.isNotEmpty) {
      final id = existentes.first['id'] as int;
      await db.update('presupuesto', p.toMap(),
          where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return await db.insert('presupuesto', p.toMap());
  }

  Future<List<Presupuesto>> getPresupuestos(String mes) async {
    final db = await database;
    final maps = await db.query(
      'presupuesto',
      where: 'mes = ?',
      whereArgs: [mes],
    );
    return maps.map((m) => Presupuesto.fromMap(m)).toList();
  }
}
