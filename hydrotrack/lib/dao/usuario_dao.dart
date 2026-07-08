import '../database/banco_dados.dart';
import '../modelo/usuario.dart';
import '../modelo/historico_peso.dart';
import 'historico_peso_dao.dart';
import 'package:intl/intl.dart';

Future<int> salvarUsuario(Usuario usuario) async {
  final db = await getDatabase();
  await db.delete('usuario');
  final id = await db.insert('usuario', usuario.toMap());

  await registrarHistoricoPeso(
    HistoricoPeso(
      peso: usuario.peso,
      altura: usuario.altura,
      imc: usuario.imc,
      metaDiariaMl: usuario.metaDiariaMl,
      dataRegistro: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    ),
  );

  return id;
}

Future<Usuario?> buscarUsuario() async {
  final db = await getDatabase();
  List<Map<String, dynamic>> result = await db.query('usuario', limit: 1);
  if (result.isEmpty) return null;
  return Usuario.fromMap(result.first);
}
