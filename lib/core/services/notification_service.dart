import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/goal.dart';

/// Servicio de notificaciones locales para recordatorios de metas con horario..
///
/// Funciona en Android/iOS. En Web (Flutter Web / Vercel) y desktop se omite
/// automáticamente: el deploy principal es Web y ahí no aplica.

abstract final class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _requestPermissions();
    _ready = true;
  }

  static Future<void> _requestPermissions() async {
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Programa un recordatorio diario recurrente ("HH:mm", 24h) para una meta.va
  static Future<void> scheduleGoalReminder({
    required String goalId,
    required String title,
    required String time,
  }) async {
    if (kIsWeb || !_ready || time.isEmpty) return;
    final parts = time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _notificationId(goalId),
      'Recordatorio: $title',
      'Es hora de trabajar en tu meta 🎯',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminders',
          'Recordatorios de metas',
          channelDescription: 'Avisos diarios para no olvidar tus metas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelGoalReminder(String goalId) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancel(_notificationId(goalId));
  }

  /// Cancela todo y reprograma los recordatorios desde cero (arranque de app..
  static Future<void> rescheduleAll(List<Goal> goals) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
    for (final g in goals) {
      final t = g.scheduledTime;
      if (t != null && t.isNotEmpty) {
        await scheduleGoalReminder(goalId: g.id, title: g.title, time: t);
      }
    }
  }

  static int _notificationId(String goalId) {
    // Hash estable por meta: el mismo id siempre => reprogramar reemplaza.

    final h = (goalId.hashCode.abs() % 2147483647);
    return h ==  0 ? 1 : h;
  }
}