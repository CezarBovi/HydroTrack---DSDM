import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common/sqflite.dart';
import 'package:path/path.dart';

Database? _database;

Future<Database> getDatabase() async {
  if (_database != null) return _database!;

  final String path = kIsWeb
      ? 'hydrotrack.db'
      : join(await getDatabasesPath(), 'hydrotrack.db');

  _database = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
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
      },
    ),
  );

  return _database!;
}