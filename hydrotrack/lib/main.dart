import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common/sqflite.dart';
import 'dao/usuario_dao.dart';
import 'telas/tela_boas_vindas.dart';
import 'telas/tela_inicial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final usuario = await buscarUsuario();

  runApp(MaterialApp(
    home: usuario == null ? const TelaBoasVindas() : const TelaInicial(),
    debugShowCheckedModeBanner: false,
  ));
}