package com.example.lae_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * AlarmReceiver - 处理系统AlarmManager发出的广播
 * 
 * 这个类解决了AlarmManager回调隔离问题：
 * - 不依赖Flutter的Dart隔离环境
 * - 直接在原生Android环境中处理alarm事件
 * - 绕过android_alarm_manager_plus插件的回调限制
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "AlarmReceiver"
        const val EXTRA_TITLE = "alarm_title"
        const val EXTRA_CONTENT = "alarm_content"
        const val EXTRA_ALARM_ID = "alarm_id"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "🚨 AlarmReceiver收到alarm广播")
        
        // 获取alarm参数
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "LAE提醒"
        val content = intent.getStringExtra(EXTRA_CONTENT) ?: "您有新的提醒"
        val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, -1)
        
        Log.d(TAG, "📱 Alarm详情 - ID: $alarmId, Title: $title, Content: $content")
        
        // 确保设备唤醒（重要：OnePlus设备可能处于深度睡眠）
        wakupDevice(context)
        
        // 启动全屏提醒Activity
        launchAlarmActivity(context, title, content, alarmId)
    }
    
    /**
     * 强力唤醒设备 - 确保设备从深度睡眠状态唤醒并点亮屏幕
     */
    private fun wakupDevice(context: Context) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            
            // 使用最强力的唤醒锁 - 点亮屏幕并保持唤醒
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "$TAG::ForceWakeLock"
            )
            
            // 延长唤醒时间到10秒，确保Activity有足够时间显示
            wakeLock.acquire(10000L)
            Log.d(TAG, "✨ 强力唤醒设备成功，屏幕应该已点亮")
            
            // 额外尝试：如果设备有键盘锁定，发送解锁信号
            try {
                val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                if (keyguardManager.isKeyguardLocked) {
                    Log.d(TAG, "🔓 检测到屏幕锁定，Activity将尝试在锁屏上显示")
                }
            } catch (e: Exception) {
                Log.w(TAG, "键盘锁定检测失败: ${e.message}")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 强力唤醒失败: ${e.message}", e)
            
            // 降级方案：至少尝试基础唤醒
            try {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val basicWakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "$TAG::BasicWakeLock"
                )
                basicWakeLock.acquire(8000L)
                Log.d(TAG, "⚡ 降级为基础唤醒")
            } catch (fallbackException: Exception) {
                Log.e(TAG, "❌ 所有唤醒方案都失败了: ${fallbackException.message}")
            }
        }
    }
    
    /**
     * 启动全屏提醒Activity
     */
    private fun launchAlarmActivity(context: Context, title: String, content: String, alarmId: Int) {
        try {
            val activityIntent = Intent(context, AlarmActivity::class.java).apply {
                // 提醒内容
                putExtra("title", title)
                putExtra("content", content)
                putExtra("alarm_id", alarmId)
                
                // 关键标志：确保Activity能在任何状态下启动
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP
                       // 注意：FLAG_ACTIVITY_TURN_SCREEN_ON 和 FLAG_ACTIVITY_SHOW_WHEN_LOCKED
                       // 在 API 27+ 中已弃用，改用Activity的manifest属性处理
            }
            
            context.startActivity(activityIntent)
            Log.d(TAG, "✅ 全屏AlarmActivity启动成功")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ AlarmActivity启动失败: ${e.message}", e)
            
            // 降级方案：发送系统通知
            fallbackToNotification(context, title, content)
        }
    }
    
    /**
     * 降级方案：如果无法启动Activity，发送通知
     */
    private fun fallbackToNotification(context: Context, title: String, content: String) {
        try {
            Log.d(TAG, "🔄 使用通知降级方案")
            
            // 这里可以实现通知发送逻辑
            // 为了简化，暂时只记录日志
            Log.w(TAG, "⚠️ 需要实现通知降级方案 - Title: $title, Content: $content")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 通知降级方案也失败了: ${e.message}", e)
        }
    }
}