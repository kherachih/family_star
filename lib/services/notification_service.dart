import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialiser les fuseaux horaires
    tz.initializeTimeZones();
    
    // Configuration pour Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration pour iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
  }

  void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // Gérer les notifications reçues en arrière-plan (iOS)
    print('Notification reçue en arrière-plan: $title - $body');
  }

  void onNotificationResponse(NotificationResponse notificationResponse) {
    // Gérer les notifications lorsque l'utilisateur appuie dessus
    print('Notification cliquée: ${notificationResponse.payload}');
  }

  Future<bool> scheduleSanctionEndNotification({
    required int id,
    required String childName,
    required String sanctionName,
    required DateTime endTime,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Sanction terminée',
        'La sanction "$sanctionName" de $childName est maintenant terminée',
        tz.TZDateTime.from(endTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sanction_end_channel',
            'Fin des sanctions',
            channelDescription: 'Notifications pour la fin des sanctions',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } on PlatformException catch (e) {
      // Gérer spécifiquement l'erreur de permission pour les alarmes exactes
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Permission pour les alarmes exactes non accordée. La notification ne sera pas planifiée.');
        return false;
      }
      // Gérer les autres erreurs
      debugPrint('Erreur lors de la planification de la notification: $e');
      return false;
    } catch (e) {
      debugPrint('Erreur inattendue lors de la planification de la notification: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}