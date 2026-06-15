import '../database/banco_dados.dart';
import '../modelo/usuario.dart';
import 'package:sqflite_common/sqflite.dart';

Future<int> salvarUsuario(Usuario usuario) async {
  final db = await getDatabase();
  // Sempre mantemos apenas 1 registro de usuário (substitui se já existir)
  await db.delete('usuario');
  return db.insert('usuario', usuario.toMap());
}

Future<Usuario?> buscarUsuario() async {
  final db = await getDatabase();
  List<Map<String, dynamic>> result = await db.query('usuario', limit: 1);
  if (result.isEmpty) return null;
  return Usuario.fromMap(result.first);
}