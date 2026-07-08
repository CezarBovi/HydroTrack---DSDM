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
import 'utilitarios/tema_controller.dart';

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

  // Carrega tema claro/escuro salvo
  await TemaController.carregarPreferencia();

  // Verifica se usuário já fez onboarding
  final usuario = await buscarUsuario();

  // Se já tem usuário, agenda notificação de água
  if (usuario != null && !kIsWeb) {
    await agendarNotificacaoAgua();
  }

  const azulPrimario = Color(0xFF2F80ED);
  const azulFundoClaro = Color(0xFFF4F8FF);
  const azulFundoEscuro = Color(0xFF0B1220);
  const azulSuperficieEscuro = Color(0xFF121A2B);

  final themeClaro = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: azulFundoClaro,
    colorScheme: ColorScheme.fromSeed(
      seedColor: azulPrimario,
      primary: azulPrimario,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: azulPrimario,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade100),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: azulPrimario, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        backgroundColor: azulPrimario,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: azulPrimario,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );

  final themeEscuro = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: azulFundoEscuro,
    colorScheme: ColorScheme.fromSeed(
      seedColor: azulPrimario,
      primary: azulPrimario,
      surface: azulSuperficieEscuro,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: azulPrimario,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: azulSuperficieEscuro,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: azulSuperficieEscuro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: azulPrimario, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        backgroundColor: azulPrimario,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: azulFundoEscuro,
      selectedItemColor: azulPrimario,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );

  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaController.temaMode,
      builder: (context, modo, _) {
        return MaterialApp(
          title: 'HydroTrack',
          debugShowCheckedModeBanner: false,
          theme: themeClaro,
          darkTheme: themeEscuro,
          themeMode: modo,
          home: usuario == null ? const TelaBoasVindas() : const TelaInicial(),
        );
      },
    ),
  );
}
