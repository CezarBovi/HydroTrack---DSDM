import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dao/usuario_dao.dart';
import 'telas/tela_boas_vindas.dart';
import 'telas/tela_inicial.dart';
import 'utilitarios/servico_notificacao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa banco de acordo com a plataforma
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa locale pt_BR para datas em português
  await initializeDateFormatting('pt_BR', null);

  // Inicializa notificações (ignorado no Web automaticamente)
  await inicializarNotificacoes();

  // Verifica se usuário já fez onboarding
  final usuario = await buscarUsuario();

  // Se já tem usuário, agenda notificação de água
  if (usuario != null && !kIsWeb) {
    await agendarNotificacaoAgua();
  }

  runApp(MaterialApp(
    title: 'HydroTrack',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: usuario == null ? const TelaBoasVindas() : const TelaInicial(),
  ));
}