package com.sentinel.sentinel_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class SyncForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                val title = intent.getStringExtra(EXTRA_TITLE)
                val text = intent.getStringExtra(EXTRA_TEXT)
                if (title != null && text != null) {
                    val notification = buildNotification(title, text)
                    val manager =
                        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.notify(NOTIFICATION_ID, notification)
                }
                return START_STICKY
            }
            else -> {
                val title = intent?.getStringExtra(EXTRA_TITLE)
                    ?: getString(R.string.sync_foreground_notification_title)
                val text = intent?.getStringExtra(EXTRA_TEXT)
                    ?: getString(R.string.sync_foreground_notification_text)
                val notification = buildNotification(title, text)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    startForeground(NOTIFICATION_ID, notification)
                }
                return START_STICKY
            }
        }
    }

    private fun buildNotification(title: String, text: String): Notification {
        createNotificationChannel()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.sync_foreground_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.sync_foreground_channel_description)
            setShowBadge(false)
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_STOP = "com.sentinel.sentinel_app.action.STOP_SYNC_FOREGROUND"
        private const val ACTION_UPDATE =
            "com.sentinel.sentinel_app.action.UPDATE_SYNC_FOREGROUND"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val CHANNEL_ID = "sentinel_sync"
        private const val NOTIFICATION_ID = 42001

        fun start(context: Context) {
            val intent = Intent(context, SyncForegroundService::class.java)
            androidx.core.content.ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, SyncForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun updateNotification(context: Context, title: String, text: String) {
            val intent = Intent(context, SyncForegroundService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_TEXT, text)
            }
            context.startService(intent)
        }
    }
}
