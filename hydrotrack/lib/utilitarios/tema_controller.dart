import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaController {
  TemaController._();

  static const _chaveTemaEscuro = 'tema_escuro';

  static final ValueNotifier<ThemeMode> temaMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static Future<void> carregarPreferencia() async {
    final prefs = await SharedPreferences.getInstance();
    final escuro = prefs.getBool(_chaveTemaEscuro) ?? false;
    temaMode.value = escuro ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setModo(ThemeMode modo) async {
    final prefs = await SharedPreferences.getInstance();
    final escuro = modo == ThemeMode.dark;
    await prefs.setBool(_chaveTemaEscuro, escuro);
    temaMode.value = modo;
  }

  static Future<void> alternar() async {
    final novo = temaMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setModo(novo);
  }
}
