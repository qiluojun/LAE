import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const platform = MethodChannel('com.example.lae_app/permissions');

  /// 检查所有必要的权限
  static Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    // 基本通知权限
    final notificationStatus = await Permission.notification.status;
    results['notification'] = notificationStatus.isGranted;

    // 精确闹钟权限
    try {
      final exactAlarmResult = await platform.invokeMethod('checkExactAlarmPermission');
      results['exactAlarm'] = exactAlarmResult as bool;
    } catch (e) {
      print('检查精确闹钟权限失败: $e');
      results['exactAlarm'] = false;
    }

    // 系统弹窗权限 (显示在其他应用上层)
    final systemAlertWindow = await Permission.systemAlertWindow.status;
    results['systemAlertWindow'] = systemAlertWindow.isGranted;

    // 电池优化权限
    try {
      final batteryOptResult = await platform.invokeMethod('checkBatteryOptimization');
      results['batteryOptimization'] = batteryOptResult as bool;
    } catch (e) {
      print('检查电池优化权限失败: $e');
      results['batteryOptimization'] = false;
    }

    // 唤醒锁权限 (通常自动授予)
    results['wakeLock'] = true; // WAKE_LOCK权限通常自动授予

    print('权限检查结果: $results');
    return results;
  }

  /// 请求所有必要的权限
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    // 1. 请求基本通知权限
    final notificationStatus = await Permission.notification.request();
    results['notification'] = notificationStatus.isGranted;
    print('通知权限结果: ${notificationStatus.isGranted}');

    // 2. 请求系统弹窗权限
    final systemAlertStatus = await Permission.systemAlertWindow.request();
    results['systemAlertWindow'] = systemAlertStatus.isGranted;
    print('系统弹窗权限结果: ${systemAlertStatus.isGranted}');

    // 3. 请求精确闹钟权限 (Android 12+)
    try {
      final exactAlarmResult = await platform.invokeMethod('requestExactAlarmPermission');
      results['exactAlarm'] = exactAlarmResult as bool;
      print('精确闹钟权限结果: $exactAlarmResult');
    } catch (e) {
      print('请求精确闹钟权限失败: $e');
      results['exactAlarm'] = false;
    }

    // 4. 请求忽略电池优化
    try {
      final batteryResult = await platform.invokeMethod('requestIgnoreBatteryOptimization');
      results['batteryOptimization'] = batteryResult as bool;
      print('电池优化权限结果: $batteryResult');
    } catch (e) {
      print('请求电池优化权限失败: $e');
      results['batteryOptimization'] = false;
    }

    return results;
  }

  /// 打开系统权限设置页面
  static Future<void> openSystemSettings() async {
    try {
      await platform.invokeMethod('openSystemSettings');
    } catch (e) {
      print('打开系统设置失败: $e');
    }
  }

  /// 打开应用详情页面
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('打开应用设置失败: $e');
    }
  }

  /// 检查权限是否完整
  static bool areAllPermissionsGranted(Map<String, bool> permissions) {
    final required = ['notification', 'systemAlertWindow', 'exactAlarm'];
    return required.every((key) => permissions[key] == true);
  }

  /// 获取缺失权限列表
  static List<String> getMissingPermissions(Map<String, bool> permissions) {
    final required = {
      'notification': '通知权限',
      'systemAlertWindow': '悬浮窗权限', 
      'exactAlarm': '精确闹钟权限',
      'batteryOptimization': '电池优化白名单'
    };

    return required.entries
        .where((entry) => permissions[entry.key] != true)
        .map((entry) => entry.value)
        .toList();
  }
}