import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'time_logic.dart';

/// Local deadline reminders. No server needed.
///
/// Uses inexact scheduling, so Android 12+ does not need the exact-alarm
/// permission. Reminders can arrive a few minutes late.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Asks for notification permission (Android 13+ and iOS). Returns true if granted.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission();
    final i = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return (a ?? i ?? true);
  }

  /// Schedules reminders 24 hours and 2 hours before [deadline].
  /// Returns how many were scheduled (past ones are skipped).
  Future<int> scheduleDeadlineReminders({
    required String clientName,
    required DateTime deadline,
  }) async {
    if (!_ready) return 0;
    final baseId = (deadline.millisecondsSinceEpoch ~/ 60000) % 100000000;
    final now = DateTime.now();
    var count = 0;
    final offsets = <int, Duration>{
      0: const Duration(hours: 24),
      1: const Duration(hours: 2),
    };
    for (final entry in offsets.entries) {
      final when = deadline.subtract(entry.value);
      if (!when.isAfter(now)) continue;
      final label = entry.value.inHours == 24 ? 'tomorrow' : 'in 2 hours';
      await _plugin.zonedSchedule(
        baseId * 2 + entry.key,
        'Deadline for $clientName $label',
        'Due ${fmtDayTime(deadline)} your time',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadlines',
            'Deadline reminders',
            channelDescription: 'Reminders before client deadlines',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      count++;
    }
    return count;
  }
}
