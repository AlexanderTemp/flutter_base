package com.example.flutter_workspace

import android.app.Application
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import com.pravera.flutter_foreground_task.service.ForegroundService
import io.flutter.embedding.engine.FlutterEngine

class TradexApplication : Application(), FlutterForegroundTaskLifecycleListener {
    override fun onCreate() {
        super.onCreate()
        ForegroundService.addTaskLifecycleListener(this)
    }

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        flutterEngine?.let { TradexNotifications.register(it, this) }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}
    override fun onTaskRepeatEvent() {}
    override fun onTaskDestroy() {}
    override fun onEngineWillDestroy() {}
}
