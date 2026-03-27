// services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
  }

  /// Schedules a notification for the last day of the current month at 8 PM.
  Future<void> scheduleMonthlyRecapReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    
    // Calculate last day of month
    // Go to first day of next month, subtract 1 day
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    
    final scheduledDate = tz.TZDateTime(
      tz.local,
      lastDay.year,
      lastDay.month,
      lastDay.day,
      20, // 8 PM
    );

    // If we're already past 8 PM on the last day, schedule for the next month's last day
    var finalDate = scheduledDate;
    if (now.isAfter(scheduledDate)) {
      final nextNextMonth = DateTime(now.year, now.month + 2, 1);
      final nextLastDay = nextNextMonth.subtract(const Duration(days: 1));
      finalDate = tz.TZDateTime(
        tz.local, 
        nextLastDay.year, 
        nextLastDay.month, 
        nextLastDay.day, 
        20
      );
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'recap_reminders',
      'Recap Reminders',
      channelDescription: 'Notifications to remind you when your Bop Recap is ready.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      999, // Unique ID for recap reminder
      'Your Bop Recap is Ready! 🎵',
      "Take a look at your listening habits from this month.",
      finalDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, 
      // Note: dayOfMonthAndTime might not work perfectly for "last day" since it's variable.
      // We will re-schedule every time the app opens to be safe.
    );
  }

  /// Shows a notification immediately for testing purposes.
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'recap_reminders',
      'Recap Reminders',
      channelDescription: 'Notifications to remind you when your Bop Recap is ready.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    await _plugin.show(
      888, 
      'Bop Notification Test 🚀', 
      'It works! You will receive your recap reminders on the last day of each month.', 
      details
    );
  }
}
