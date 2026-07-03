package com.sentinel.sentinel_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    SyncForegroundService.start(this)
                    result.success(null)
                }
                "stopForegroundService" -> {
                    SyncForegroundService.stop(this)
                    result.success(null)
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermissionIfNeeded()
                    result.success(null)
                }
                "updateForegroundNotification" -> {
                    val title = call.argument<String>("title")
                    val text = call.argument<String>("text")
                    if (title != null && text != null) {
                        SyncForegroundService.updateNotification(this, title, text)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            POST_NOTIFICATIONS_REQUEST_CODE,
        )
    }

    companion object {
        private const val CHANNEL_NAME = "com.sentinel.sentinel_app/sync_foreground"
        private const val POST_NOTIFICATIONS_REQUEST_CODE = 42042
    }
}
