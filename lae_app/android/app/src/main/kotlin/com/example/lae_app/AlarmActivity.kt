package com.example.lae_app

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.os.PowerManager
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AlarmActivity : Activity() {
    
    private var wakeLock: PowerManager.WakeLock? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 设置全屏显示
        setupFullScreen()
        
        // 获取wake lock保持屏幕唤醒
        acquireWakeLock()
        
        // 设置布局
        setContentView(R.layout.activity_alarm)
        
        // 获取提醒内容
        val reminderTitle = intent.getStringExtra("title") ?: "LAE提醒"
        val reminderContent = intent.getStringExtra("content") ?: "您有新的提醒"
        
        val titleView = findViewById<TextView>(R.id.reminder_title)
        val contentView = findViewById<TextView>(R.id.reminder_content)
        val dismissButton = findViewById<Button>(R.id.dismiss_button)
        
        titleView.text = reminderTitle
        contentView.text = reminderContent
        
        dismissButton.setOnClickListener { dismissAlarm() }
        
        println("🚨 AlarmActivity启动成功 - 标题: $reminderTitle, 内容: $reminderContent")
    }
    
    private fun setupFullScreen() {
        // 设置窗口flags实现锁屏显示
        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
    }
    
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "LAEApp:AlarmWakeLock"
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10分钟超时
        
        println("✅ WakeLock已获取")
    }
    
    private fun dismissAlarm() {
        // 释放wake lock
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                println("🔓 WakeLock已释放")
            }
        }
        
        // 关闭Activity
        finish()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        println("🔚 AlarmActivity已销毁")
    }
    
    override fun onBackPressed() {
        // 防止用户按返回键意外关闭
        // 可以根据需要决定是否允许返回键关闭
        dismissAlarm()
    }
}