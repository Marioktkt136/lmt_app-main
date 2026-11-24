package com.example.lmt

import android.app.job.JobParameters
import android.app.job.JobService
import java.util.concurrent.Executors

/**
 * Periodic Android JobScheduler backup ensuring background & lock-screen alerts
 * still fire even if the OS or battery saver terminates the foreground service.
 */
class LmtBackgroundSyncJobService : JobService() {
    private val worker = Executors.newSingleThreadExecutor()

    override fun onStartJob(params: JobParameters?): Boolean {
        val appCtx = applicationContext
        if (!LmtBackgroundNotificationManager.isSessionActive(appCtx)) {
            return false
        }
        worker.execute {
            try {
                LmtBackgroundNotificationManager.pollAndAlertIfNeeded(appCtx)
                LmtBackgroundNotificationManager.startSyncServiceSafely(appCtx)
            } catch (_: Exception) {
            } finally {
                jobFinished(params, false)
            }
        }
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean = true

    override fun onDestroy() {
        worker.shutdownNow()
        super.onDestroy()
    }
}
