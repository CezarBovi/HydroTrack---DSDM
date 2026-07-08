import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

Database? _database;

Future<Database> getDatabase() async {
  if (_database != null) return _database!;

  String path = join(await getDatabasesPath(), 'hydrotrack.db');

  _database = await openDatabase(
    path,
    version: 2,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE usuario (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          peso REAL NOT NULL,
          altura REAL NOT NULL,
          imc REAL NOT NULL,
          meta_diaria_ml REAL NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE consumo_agua (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          data TEXT NOT NULL,
          horario TEXT NOT NULL,
          quantidade_ml INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE lembretes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT NOT NULL,
          horario TEXT NOT NULL,
          intervalo_horas INTEGER NOT NULL,
          dias_semana TEXT NOT NULL,
          ativo INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await _criarTabelaHistoricoPeso(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _criarTabelaHistoricoPeso(db);
      }
    },
  );

  return _database!;
}

Future<void> _criarTabelaHistoricoPeso(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS historico_peso (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      peso REAL NOT NULL,
      altura REAL NOT NULL,
      imc REAL NOT NULL,
      meta_diaria_ml REAL NOT NULL,
      data_registro TEXT NOT NULL
    )
  ''');
}