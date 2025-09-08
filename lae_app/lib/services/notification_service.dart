import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // The init method now correctly uses a named parameter.
  Future<void> init({
    required void Function(NotificationResponse)
        onDidReceiveNotificationResponse,
  }) async {
    // Initialize time zones
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Default app icon

    // iOS/macOS initialization settings (can be configured further if needed)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Request notification permissions on Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleDailySurveyNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      '状态记录提醒', // Notification title
      '今天过得如何？请记录一下你当前的状态吧！', // Notification body
      _nextInstanceOf23PM(), // The scheduled time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_survey_channel', // Channel ID
          'Daily Survey Notifications', // Channel name
          channelDescription: 'Channel for daily status survey reminders.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at the same time
    );
  }

  // 添加测试提醒功能，10秒后弹出提醒
  Future<void> scheduleTestNotification() async {
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    print('NotificationService: 准备在 ${scheduledDate.toString()} 设置测试提醒');
    print(
        'NotificationService: 当前时间是 ${tz.TZDateTime.now(tz.local).toString()}');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        999, // 使用特殊的ID，避免与其他提醒冲突
        '测试提醒',
        '这是一个10秒后的测试提醒！功能正常工作。',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notification_channel',
            'Test Notifications',
            channelDescription:
                'Channel for testing notification functionality.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            autoCancel: false,
            ongoing: false,
            enableVibration: true,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('NotificationService: 测试提醒调度成功');
    } catch (e) {
      print('NotificationService: 调度测试提醒时出错: $e');
      rethrow;
    }
  }

  // 添加短时间测试提醒功能，3秒后弹出
  Future<void> scheduleShortTestNotification() async {
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3));

    print('NotificationService: 准备在 ${scheduledDate.toString()} 设置3秒测试提醒');
    print(
        'NotificationService: 当前时间是 ${tz.TZDateTime.now(tz.local).toString()}');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        997, // 不同的ID
        '3秒测试提醒',
        '这是一个3秒后的测试提醒！',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'short_test_channel',
            'Short Test Notifications',
            channelDescription:
                'Channel for short interval test notifications.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            autoCancel: false,
            ongoing: false,
            enableVibration: true,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('NotificationService: 3秒测试提醒调度成功');
    } catch (e) {
      print('NotificationService: 调度3秒测试提醒时出错: $e');
      rethrow;
    }
  }

  // 添加立即测试提醒功能
  Future<void> showImmediateTestNotification() async {
    print('NotificationService: 显示立即测试提醒');

    try {
      await flutterLocalNotificationsPlugin.show(
        998, // 不同的ID
        '立即测试提醒',
        '这是一个立即显示的测试提醒！如果你看到这个，说明基本通知功能正常。',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'immediate_test_channel',
            'Immediate Test Notifications',
            channelDescription: 'Channel for immediate test notifications.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
      );
      print('NotificationService: 立即测试提醒显示成功');
    } catch (e) {
      print('NotificationService: 显示立即测试提醒时出错: $e');
      rethrow;
    }
  }

  // 添加取消所有测试提醒的功能
  Future<void> cancelAllTestNotifications() async {
    print('NotificationService: 取消所有测试提醒');

    try {
      await flutterLocalNotificationsPlugin.cancel(999); // 取消10秒测试提醒
      await flutterLocalNotificationsPlugin.cancel(998); // 取消立即测试提醒
      await flutterLocalNotificationsPlugin.cancel(997); // 取消3秒测试提醒
      print('NotificationService: 所有测试提醒已取消');
    } catch (e) {
      print('NotificationService: 取消测试提醒时出错: $e');
      rethrow;
    }
  }

  // 检查和请求所有必要的权限
  Future<Map<String, bool>> checkAndRequestPermissions() async {
    Map<String, bool> permissionStatus = {};

    if (Platform.isAndroid) {
      // 检查通知权限
      final notificationStatus = await Permission.notification.status;
      permissionStatus['notification'] = notificationStatus.isGranted;

      // 检查精确闹钟权限 (Android 12+)
      final scheduleExactAlarmStatus =
          await Permission.scheduleExactAlarm.status;
      permissionStatus['scheduleExactAlarm'] =
          scheduleExactAlarmStatus.isGranted;

      // 检查是否在电池优化白名单中
      final ignoreBatteryOptimizationsStatus =
          await Permission.ignoreBatteryOptimizations.status;
      permissionStatus['ignoreBatteryOptimizations'] =
          ignoreBatteryOptimizationsStatus.isGranted;

      print('权限状态检查结果:');
      print('通知权限: ${permissionStatus['notification']}');
      print('精确闹钟权限: ${permissionStatus['scheduleExactAlarm']}');
      print('电池优化白名单: ${permissionStatus['ignoreBatteryOptimizations']}');

      // 请求缺失的权限
      List<Permission> permissionsToRequest = [];

      if (!permissionStatus['notification']!) {
        permissionsToRequest.add(Permission.notification);
      }

      if (!permissionStatus['scheduleExactAlarm']!) {
        permissionsToRequest.add(Permission.scheduleExactAlarm);
      }

      if (!permissionStatus['ignoreBatteryOptimizations']!) {
        permissionsToRequest.add(Permission.ignoreBatteryOptimizations);
      }

      if (permissionsToRequest.isNotEmpty) {
        print(
            '请求权限: ${permissionsToRequest.map((p) => p.toString()).join(', ')}');
        final Map<Permission, PermissionStatus> results =
            await permissionsToRequest.request();

        // 更新权限状态
        if (results.containsKey(Permission.notification)) {
          permissionStatus['notification'] =
              results[Permission.notification]!.isGranted;
        }
        if (results.containsKey(Permission.scheduleExactAlarm)) {
          permissionStatus['scheduleExactAlarm'] =
              results[Permission.scheduleExactAlarm]!.isGranted;
        }
        if (results.containsKey(Permission.ignoreBatteryOptimizations)) {
          permissionStatus['ignoreBatteryOptimizations'] =
              results[Permission.ignoreBatteryOptimizations]!.isGranted;
        }

        print('权限请求后状态:');
        print('通知权限: ${permissionStatus['notification']}');
        print('精确闹钟权限: ${permissionStatus['scheduleExactAlarm']}');
        print('电池优化白名单: ${permissionStatus['ignoreBatteryOptimizations']}');
      }
    }

    return permissionStatus;
  }

  tz.TZDateTime _nextInstanceOf23PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 23); // 23:00 is 11 PM
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
