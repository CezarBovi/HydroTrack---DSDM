import 'package:intl/intl.dart';
import '../database/banco_dados.dart';
import '../modelo/historico_peso.dart';

Future<int> registrarHistoricoPeso(HistoricoPeso registro) async {
  final db = await getDatabase();
  return db.insert('historico_peso', registro.toMap());
}

Future<List<HistoricoPeso>> listarHistoricoPeso() async {
  final db = await getDatabase();
  final result = await db.query(
    'historico_peso',
    orderBy: 'data_registro ASC',
  );
  return result.map(HistoricoPeso.fromMap).toList();
}

Future<void> migrarUsuarioAtualParaHistorico() async {
  final db = await getDatabase();
  final usuario = await db.query('usuario', limit: 1);
  if (usuario.isEmpty) return;

  final count = await db.rawQuery('SELECT COUNT(*) as total FROM historico_peso');
  if ((count.first['total'] as num).toInt() > 0) return;

  final u = usuario.first;
  await db.insert('historico_peso', {
    'peso': u['peso'],
    'altura': u['altura'],
    'imc': u['imc'],
    'meta_diaria_ml': u['meta_diaria_ml'],
    'data_registro': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
  });
}
