import '../database/banco_dados.dart';
import '../modelo/lembrete.dart';
import 'package:sqflite_common/sqflite.dart';

Future<int> inserirLembrete(Lembrete lembrete) async {
  final db = await getDatabase();
  return db.insert('lembretes', lembrete.toMap());
}

Future<List<Map<String, dynamic>>> listarLembretes() async {
  final db = await getDatabase();
  return db.query('lembretes', orderBy: 'horario ASC');
}

Future<int> atualizarStatusLembrete(int id, int ativo) async {
  final db = await getDatabase();
  return db.update(
    'lembretes',
    {'ativo': ativo},
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> deletarLembrete(int id) async {
  final db = await getDatabase();
  return db.delete('lembretes', where: 'id = ?', whereArgs: [id]);
}