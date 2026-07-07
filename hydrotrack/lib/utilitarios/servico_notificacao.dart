import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final FlutterLocalNotificationsPlugin notificacoes =
    FlutterLocalNotificationsPlugin();


Future<void> inicializarNotificacoes() async {
  if (kIsWeb) return;

  tz.initializeTimeZones();

  try {
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(
      tz.getLocation(timezone.identifier),
    );
  } catch (e) {
    tz.setLocalLocation(
      tz.getLocation('America/Sao_Paulo'),
    );
  }


  const AndroidInitializationSettings android =
      AndroidInitializationSettings('@mipmap/ic_launcher');


  const InitializationSettings settings =
      InitializationSettings(
        android: android,
      );


  await notificacoes.initialize(
    settings: settings,
  );


  final androidImplementation =
      notificacoes.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidImplementation?.requestNotificationsPermission();
  await androidImplementation?.requestExactAlarmsPermission();
}



// Notificação de água — dispara de hora em hora
Future<void> agendarNotificacaoAgua() async {
  if (kIsWeb) return;


  const AndroidNotificationDetails android =
      AndroidNotificationDetails(
    'canal_agua',
    'Lembretes de água',
    channelDescription:
        'Notificações para lembrar de beber água',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );


  const NotificationDetails detalhes =
      NotificationDetails(
        android: android,
      );


  await notificacoes.cancel(
    id: 0,
  );


  await notificacoes.zonedSchedule(
    id: 0,
    title: '💧 Hora de beber água!',
    body:
        'Você não registrou consumo na última hora. Beba um copo agora!',
    scheduledDate:
        tz.TZDateTime.now(tz.local).add(
          const Duration(hours: 1),
        ),
    notificationDetails: detalhes,
    androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,
  );
}



// Cancela a notificação de água
Future<void> cancelarNotificacaoAgua() async {
  if (kIsWeb) return;

  await notificacoes.cancel(
    id: 0,
  );
}



// Reagenda após consumo
Future<void> reagendarAposConsumo() async {
  if (kIsWeb) return;

  await cancelarNotificacaoAgua();
  await agendarNotificacaoAgua();
}



// Agenda notificação personalizada
Future<void> agendarLembrete({
  required int id,
  required String titulo,
  required String horario,
  required int intervaloHoras,
}) async {

  if (kIsWeb) return;


  const AndroidNotificationDetails android =
      AndroidNotificationDetails(
    'canal_lembretes',
    'Lembretes personalizados',
    channelDescription:
        'Notificações de lembretes do usuário',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );


  const NotificationDetails detalhes =
      NotificationDetails(
        android: android,
      );


  final partes = horario.split(':');

  final hora = int.parse(partes[0]);
  final minuto = int.parse(partes[1]);


  final agora = tz.TZDateTime.now(
    tz.local,
  );


  final base = tz.TZDateTime(
    tz.local,
    agora.year,
    agora.month,
    agora.day,
    hora,
    minuto,
  );


  int ocorrencias = 1;
  int passoHoras = 24;


  if (intervaloHoras > 0) {
    ocorrencias =
        (24 / intervaloHoras).ceil();

    passoHoras = intervaloHoras;
  }


  await cancelarLembrete(id);



  for (int i = 0; i < ocorrencias; i++) {

    var proximo = base.add(
      Duration(
        hours: i * passoHoras,
      ),
    );


    if (proximo.isBefore(agora)) {
      proximo = proximo.add(
        const Duration(days: 1),
      );
    }


    final int idNotificacao =
        id * 100 + i;



    await notificacoes.zonedSchedule(
      id: idNotificacao,
      title: '🔔 $titulo',
      body: 'Seu lembrete está ativo!',
      scheduledDate: proximo,
      notificationDetails: detalhes,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );
  }
}



// Cancela um lembrete específico
Future<void> cancelarLembrete(
  int id,
) async {

  if (kIsWeb) return;


  await notificacoes.cancel(
    id: id,
  );


  for (int i = 0; i < 24; i++) {

    await notificacoes.cancel(
      id: id * 100 + i,
    );

  }
}



// Cancela todos os lembretes
Future<void> cancelarTodosLembretes() async {

  if (kIsWeb) return;

  await notificacoes.cancelAll();

}
