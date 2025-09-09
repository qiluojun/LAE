import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';

class AlarmManagerService {
  static const platform = MethodChannel('com.example.lae_app/alarm');
  
  /// 初始化AlarmManager服务
  static Future<bool> initialize() async {
    if (Platform.isAndroid) {
      return await AndroidAlarmManager.initialize();
    }
    return false;
  }
  
  /// 调度一次性提醒
  /// [id] 提醒唯一标识
  /// [dateTime] 提醒时间
  /// [title] 提醒标题
  /// [content] 提醒内容
  static Future<bool> scheduleOneTimeAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String content,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      // 使用AndroidAlarmManager调度alarm
      final success = await AndroidAlarmManager.oneShotAt(
        dateTime,
        id,
        _alarmCallback,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'title': title,
          'content': content,
          'id': id,
        },
      );
      
      print('AlarmManager调度结果: $success, 时间: $dateTime, 标题: $title');
      return success;
    } catch (e) {
      print('AlarmManager调度失败: $e');
      return false;
    }
  }
  
  /// 调度重复提醒
  static Future<bool> scheduleRepeatingAlarm({
    required int id,
    required DateTime startTime,
    required Duration interval,
    required String title,
    required String content,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final success = await AndroidAlarmManager.periodic(
        interval,
        id,
        _alarmCallback,
        startAt: startTime,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: {
          'title': title,
          'content': content,
          'id': id,
        },
      );
      
      print('重复AlarmManager调度结果: $success, 开始时间: $startTime, 间隔: $interval');
      return success;
    } catch (e) {
      print('重复AlarmManager调度失败: $e');
      return false;
    }
  }
  
  /// 取消指定的提醒
  static Future<bool> cancelAlarm(int id) async {
    if (!Platform.isAndroid) return false;
    
    try {
      await AndroidAlarmManager.cancel(id);
      print('已取消Alarm: $id');
      return true;
    } catch (e) {
      print('取消Alarm失败: $e');
      return false;
    }
  }
  
  /// 取消所有提醒
  static Future<bool> cancelAllAlarms() async {
    if (!Platform.isAndroid) return false;
    
    try {
      await AndroidAlarmManager.cancel(-1); // 取消所有
      print('已取消所有Alarms');
      return true;
    } catch (e) {
      print('取消所有Alarms失败: $e');
      return false;
    }
  }
  
  /// Alarm回调函数 - 这个函数在Alarm触发时被调用
  @pragma('vm:entry-point')
  static void _alarmCallback(int id, Map<String, dynamic> params) async {
    print('🚨🚨🚨 Alarm触发开始! ID: $id, 参数: $params');
    
    final title = params['title'] ?? 'LAE提醒';
    final content = params['content'] ?? '您有新的提醒';
    
    print('📱 准备启动全屏Activity: $title - $content');
    
    // 启动全屏Activity
    await _launchFullScreenAlarm(title, content);
    
    print('🔚 Alarm回调处理完成');
  }
  
  /// 启动全屏提醒Activity
  static Future<void> _launchFullScreenAlarm(String title, String content) async {
    print('🔧 开始调用MethodChannel...');
    
    // 首先尝试直接方案
    try {
      print('📞 调用launchAlarmActivity方法');
      final result = await platform.invokeMethod('launchAlarmActivity', {
        'title': title,
        'content': content,
      });
      print('✅ 全屏提醒Activity启动成功，返回值: $result');
      return; // 成功则直接返回
    } catch (e) {
      print('❌ 启动全屏提醒Activity失败: $e');
      print('🔧 错误类型: ${e.runtimeType}');
    }
    
    // 降级方案1：尝试不同的方法
    await _fallbackStartActivity(title, content);
  }
  
  /// 降级方案：直接启动Activity
  static Future<void> _fallbackStartActivity(String title, String content) async {
    try {
      print('🔄 尝试降级方案：直接启动Activity');
      
      // 尝试使用Android Intent启动
      await platform.invokeMethod('startActivityDirectly', {
        'className': 'com.example.lae_app.AlarmActivity',
        'title': title,
        'content': content,
      });
      
      print('✅ 降级方案成功');
    } catch (e) {
      print('❌ 降级方案也失败了: $e');
      
      // 最终降级：尝试通过Android原生方式
      await _finalFallback(title, content);
    }
  }
  
  /// 最终降级方案：直接创建Android意图
  static Future<void> _finalFallback(String title, String content) async {
    try {
      print('🔔 最终降级方案：尝试原生Android意图');
      
      // 创建一个简单的通知作为测试
      await platform.invokeMethod('showTestNotification', {
        'title': title,
        'content': content,
      });
      
      print('✅ 通知降级方案执行完成');
    } catch (e) {
      print('❌ 所有方案都失败了: $e');
      print('⚠️ 可能需要检查应用架构或权限配置');
    }
  }
  
  /// 调度测试提醒（用于测试功能）
  static Future<bool> scheduleTestAlarm({
    int delaySeconds = 10,
    String title = '测试提醒',
    String content = '这是一个测试提醒，用于验证息屏弹窗功能',
  }) async {
    final testTime = DateTime.now().add(Duration(seconds: delaySeconds));
    final testId = DateTime.now().millisecondsSinceEpoch % 10000; // 简单的测试ID
    
    print('📅 调度测试提醒: $testTime ($delaySeconds秒后)');
    
    return await scheduleOneTimeAlarm(
      id: testId,
      dateTime: testTime,
      title: title,
      content: content,
    );
  }
  
  /// 新方法：使用原生AlarmManager调度提醒，绕过Flutter回调隔离问题
  static Future<bool> scheduleNativeAlarm({
    required int id,
    required String title,
    required String content,
    int delaySeconds = 10,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      print('🕒 调用原生AlarmManager - ID: $id, 延时: ${delaySeconds}秒');
      print('📱 提醒内容: $title - $content');
      
      final result = await platform.invokeMethod('scheduleNativeAlarm', {
        'alarmId': id,
        'title': title,
        'content': content,
        'delaySeconds': delaySeconds,
      });
      
      print('✅ 原生AlarmManager调度结果: $result');
      return result == true;
    } catch (e) {
      print('❌ 原生AlarmManager调度失败: $e');
      return false;
    }
  }
  
  /// 原生测试方法
  static Future<bool> scheduleNativeTestAlarm({
    int delaySeconds = 10,
    String title = '原生测试提醒',
    String content = '这是原生AlarmManager测试，绕过Flutter回调隔离问题',
  }) async {
    final testId = DateTime.now().millisecondsSinceEpoch % 10000;
    
    print('🧪 调度原生测试提醒: ${delaySeconds}秒后触发');
    
    return await scheduleNativeAlarm(
      id: testId,
      title: title,
      content: content,
      delaySeconds: delaySeconds,
    );
  }
}