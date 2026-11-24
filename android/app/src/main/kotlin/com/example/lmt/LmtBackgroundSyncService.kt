package com.example.lmt

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.ServiceCompat
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Lightweight Android foreground service keeping background & lock-screen
 * notification checks active every 12 seconds while a user session is signed in.
 */
class LmtBackgroundSyncService : Service() {
    private var executor: ScheduledExecutorService? = null
    private var pollFuture: ScheduledFuture<*>? = null

    override fun onCreate() {
        super.onCreate()
        startForegroundSafely()
        executor = Executors.newSingleThreadScheduledExecutor()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundSafely()
        if (!LmtBackgroundNotificationManager.isSessionActive(applicationContext)) {
            stopSelf()
            return START_NOT_STICKY
        }

        if (pollFuture == null || pollFuture?.isCancelled == true || pollFuture?.isDone == true) {
            pollFuture = executor?.scheduleWithFixedDelay(
                {
                    try {
                        if (!LmtBackgroundNotificationManager.isSessionActive(applicationContext)) {
                            stopSelf()
                        } else {
                            LmtBackgroundNotificationManager.pollAndAlertIfNeeded(applicationContext)
                        }
                    } catch (_: Exception) {
                    }
                },
                5L,
                12L,
                TimeUnit.SECONDS
            )
        }
        return START_STICKY
    }

    private fun startForegroundSafely() {
        val notification = LmtBackgroundNotificationManager.buildForegroundServiceNotification(this)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceCompat.startForeground(
                    this,
                    LmtBackgroundNotificationManager.FG_SERVICE_NOTIF_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING
                )
            } else {
                startForeground(LmtBackgroundNotificationManager.FG_SERVICE_NOTIF_ID, notification)
            }
        } catch (_: Exception) {
            try {
                startForeground(LmtBackgroundNotificationManager.FG_SERVICE_NOTIF_ID, notification)
            } catch (_: Exception) {
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (LmtBackgroundNotificationManager.isSessionActive(applicationContext)) {
            LmtBackgroundNotificationManager.schedulePeriodicJob(applicationContext)
        }
    }

    override fun onDestroy() {
        pollFuture?.cancel(true)
        pollFuture = null
        executor?.shutdownNow()
        executor = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
