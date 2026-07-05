import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin notificacoes =
    FlutterLocalNotificationsPlugin();

Future<void> inicializarNotificacoes() async {
  // Não inicializa no Web
  if (kIsWeb) return;

  tz.initializeTimeZones();

  const AndroidInitializationSettings android =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(android: android);

  await notificacoes.initialize(settings);
}

// Notificação de água — dispara de hora em hora
Future<void> agendarNotificacaoAgua() async {
  if (kIsWeb) return;

  const AndroidNotificationDetails android = AndroidNotificationDetails(
    'canal_agua',
    'Lembretes de água',
    channelDescription: 'Notificações para lembrar de beber água',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails detalhes =
      NotificationDetails(android: android);

  // Cancela a notificação anterior antes de reagendar
  await notificacoes.cancel(0);

  // Agenda para daqui a 1 hora
  await notificacoes.zonedSchedule(
    0,
    '💧 Hora de beber água!',
    'Você não registrou consumo na última hora. Beba um copo agora!',
    tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
    detalhes,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

// Cancela a notificação de água (quando o usuário bebe)
Future<void> cancelarNotificacaoAgua() async {
  if (kIsWeb) return;
  await notificacoes.cancel(0);
}

// Reagenda após o usuário beber (próxima notificação daqui a 1 hora)
Future<void> reagendarAposConsumo() async {
  if (kIsWeb) return;
  await cancelarNotificacaoAgua();
  await agendarNotificacaoAgua();
}

// Agenda notificação de lembrete personalizado
Future<void> agendarLembrete({
  required int id,
  required String titulo,
  required String horario, // 'HH:mm'
  required int intervaloHoras,
}) async {
  if (kIsWeb) return;

  const AndroidNotificationDetails android = AndroidNotificationDetails(
    'canal_lembretes',
    'Lembretes personalizados',
    channelDescription: 'Notificações de lembretes do usuário',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails detalhes =
      NotificationDetails(android: android);

  final partes = horario.split(':');
  final hora = int.parse(partes[0]);
  final minuto = int.parse(partes[1]);

  // Monta o próximo horário do lembrete
  final agora = tz.TZDateTime.now(tz.local);
  var proximo = tz.TZDateTime(
    tz.local,
    agora.year,
    agora.month,
    agora.day,
    hora,
    minuto,
  );

  // Se o horário já passou hoje, agenda para amanhã
  if (proximo.isBefore(agora)) {
    proximo = proximo.add(const Duration(days: 1));
  }

  await notificacoes.zonedSchedule(
    id,
    '🔔 $titulo',
    'Seu lembrete está ativo!',
    proximo,
    detalhes,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

// Cancela um lembrete específico
Future<void> cancelarLembrete(int id) async {
  if (kIsWeb) return;
  await notificacoes.cancel(id);
}

// Cancela todos os lembretes
Future<void> cancelarTodosLembretes() async {
  if (kIsWeb) return;
  await notificacoes.cancelAll();
}