package com.example.lae_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val ALARM_CHANNEL = "com.example.lae_app/alarm"
    private val PERMISSION_CHANNEL = "com.example.lae_app/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 闹钟相关的MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAlarmActivity" -> {
                    val title = call.argument<String>("title") ?: "LAE提醒"
                    val content = call.argument<String>("content") ?: "您有新的提醒"
                    
                    println("🚀 MainActivity收到启动Activity请求: $title")
                    
                    try {
                        val intent = Intent(this, AlarmActivity::class.java).apply {
                            putExtra("title", title)
                            putExtra("content", content)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                                   Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                   Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        startActivity(intent)
                        println("✅ Activity启动命令已发送")
                        result.success(true)
                    } catch (e: Exception) {
                        println("❌ Activity启动失败: ${e.message}")
                        result.error("ALARM_ERROR", "无法启动提醒Activity: ${e.message}", null)
                    }
                }
                "startActivityDirectly" -> {
                    val title = call.argument<String>("title") ?: "LAE提醒"
                    val content = call.argument<String>("content") ?: "您有新的提醒"
                    
                    try {
                        val intent = Intent().apply {
                            setClassName(this@MainActivity, "com.example.lae_app.AlarmActivity")
                            putExtra("title", title)
                            putExtra("content", content)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", "直接启动Activity失败: ${e.message}", null)
                    }
                }
                "showTestNotification" -> {
                    val title = call.argument<String>("title") ?: "LAE提醒"
                    val content = call.argument<String>("content") ?: "您有新的提醒"
                    
                    try {
                        println("🔔 收到通知请求: $title - $content")
                        
                        // 创建一个强制的全屏Intent
                        val intent = Intent(this, AlarmActivity::class.java).apply {
                            putExtra("title", title)
                            putExtra("content", content)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                   Intent.FLAG_ACTIVITY_CLEAR_TASK or
                                   Intent.FLAG_ACTIVITY_NO_HISTORY
                        }
                        
                        startActivity(intent)
                        println("✅ 强制全屏Intent已发送")
                        result.success(true)
                    } catch (e: Exception) {
                        println("❌ 通知降级方案失败: ${e.message}")
                        result.error("NOTIFICATION_ERROR", "通知失败: ${e.message}", null)
                    }
                }
                "scheduleNativeAlarm" -> {
                    val title = call.argument<String>("title") ?: "LAE提醒"
                    val content = call.argument<String>("content") ?: "您有新的提醒"
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                    val alarmId = call.argument<Int>("alarmId") ?: System.currentTimeMillis().toInt()
                    
                    try {
                        val success = scheduleNativeAlarmManager(alarmId, title, content, delaySeconds)
                        result.success(success)
                    } catch (e: Exception) {
                        println("❌ 原生AlarmManager调度失败: ${e.message}")
                        result.error("NATIVE_ALARM_ERROR", "原生闹钟调度失败: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // 权限相关的MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true) // Android 12以下默认有权限
                    }
                }
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "checkBatteryOptimization" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                }
                "requestIgnoreBatteryOptimization" -> {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("BATTERY_ERROR", "请求电池优化权限失败: ${e.message}", null)
                    }
                }
                "openSystemSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", "打开系统设置失败: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    /**
     * 原生AlarmManager调度方法 - 绕过Flutter插件的回调隔离问题
     * 直接使用Android系统AlarmManager发送广播到我们自定义的BroadcastReceiver
     */
    private fun scheduleNativeAlarmManager(alarmId: Int, title: String, content: String, delaySeconds: Int): Boolean {
        return try {
            println("🕒 开始调度原生AlarmManager - ID: $alarmId, 延时: ${delaySeconds}秒")
            
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            
            // 创建广播Intent发送到我们的AlarmReceiver
            val alarmIntent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra(AlarmReceiver.EXTRA_TITLE, title)
                putExtra(AlarmReceiver.EXTRA_CONTENT, content)
                putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            }
            
            // 创建PendingIntent
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                alarmId,
                alarmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // 计算触发时间
            val triggerTime = System.currentTimeMillis() + (delaySeconds * 1000L)
            val calendar = Calendar.getInstance().apply {
                timeInMillis = triggerTime
            }
            
            println("📅 计划触发时间: ${calendar.time}")
            
            // 调度精确的alarm
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Android 6.0+ 使用 setExactAndAllowWhileIdle 确保在低电耗模式下也能触发
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
                println("✅ 使用 setExactAndAllowWhileIdle 调度成功")
            } else {
                // 老版本Android使用setExact
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
                println("✅ 使用 setExact 调度成功")
            }
            
            true
        } catch (e: Exception) {
            println("❌ 原生AlarmManager调度异常: ${e.message}")
            e.printStackTrace()
            false
        }
    }
}
