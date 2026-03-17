import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleWaterReminder() async {
    await requestPermissions();
    await _plugin.cancelAll();

    // Water reminders every 2 hours from 08:00 to 22:00
    for (int hour = 8; hour <= 22; hour += 2) {
      await _scheduleDaily(
        id: hour,
        title: 'Su İçme Hatırlatması',
        body: 'Bir bardak su içmeyi unutma! Kalp sağlığın için su çok önemli.',
        hour: hour,
        minute: 0,
      );
    }

    // Movement reminders
    final movementHours = [10, 14, 17];
    for (int i = 0; i < movementHours.length; i++) {
      await _scheduleDaily(
        id: 100 + i,
        title: 'Hareket Hatırlatması',
        body: 'Biraz yürüyüş yapmaya ne dersin? Kalbin sana teşekkür edecek!',
        hour: movementHours[i],
        minute: 30,
      );
    }

    // Blood pressure reminders
    await _scheduleDaily(
      id: 200,
      title: 'Tansiyon Ölçümü',
      body: 'Sabah tansiyon ölçümünü yapmayı unutma!',
      hour: 9,
      minute: 0,
    );
    await _scheduleDaily(
      id: 201,
      title: 'Tansiyon Ölçümü',
      body: 'Akşam tansiyon ölçümünü yapmayı unutma!',
      hour: 21,
      minute: 0,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'kalp_sagligi_channel',
          'Kalp Sağlığı Bildirimleri',
          channelDescription: 'Sağlık hatırlatmaları',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
