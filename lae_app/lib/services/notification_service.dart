import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String surveyChannelId = 'survey_channel';
  static const String surveyPayload = 'daily_survey';

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // const DarwinInitializationSettings initializationSettingsIOS =
    //     DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid
            // ios: initializationSettingsIOS,
            );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == surveyPayload) {
          navigatorKey.currentState?.pushNamed('/survey');
        }
      },
    );
  }

  Future<void> scheduleDailySurveyNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '每日状态记录',
      '今天感觉如何？点击这里记录你的状态。',
      _nextInstanceOf23PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          surveyChannelId,
          '每日问卷通知',
          channelDescription: '用于提醒用户填写每日状态问卷的通知',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at the same time
      payload: surveyPayload,
    );
  }

  tz.TZDateTime _nextInstanceOf23PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 23);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
