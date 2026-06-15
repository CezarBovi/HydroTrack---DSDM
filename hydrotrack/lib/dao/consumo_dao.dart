import '../database/banco_dados.dart';
import '../modelo/consumo.dart';
import 'package:sqflite_common/sqflite.dart';

Future<int> registrarConsumo(Consumo consumo) async {
  final db = await getDatabase();
  return db.insert('consumo_agua', consumo.toMap());
}

Future<List<Map<String, dynamic>>> buscarConsumoPorData(String data) async {
  final db = await getDatabase();
  return db.query('consumo_agua', where: 'data = ?', whereArgs: [data]);
}

Future<int> totalConsumidoNoDia(String data) async {
  final db = await getDatabase();
  final result = await db.rawQuery(
    'SELECT SUM(quantidade_ml) as total FROM consumo_agua WHERE data = ?',
    [data],
  );
  final total = result.first['total'];
  return total == null ? 0 : (total as int);
}

Future<bool> jaConsumiuNoHorario(String data, String horario) async {
  final db = await getDatabase();
  final result = await db.query(
    'consumo_agua',
    where: 'data = ? AND horario = ?',
    whereArgs: [data, horario],
  );
  return result.isNotEmpty;
}

Future<List<Map<String, dynamic>>> buscarUltimosDias(int dias) async {
  final db = await getDatabase();
  return db.rawQuery('''
    SELECT data, SUM(quantidade_ml) as total
    FROM consumo_agua
    GROUP BY data
    ORDER BY data DESC
    LIMIT ?
  ''', [dias]);
}