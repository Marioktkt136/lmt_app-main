package com.example.lmt

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores background notification monitoring and JobScheduler registration
 * automatically after phone reboot or app updates.
 */
class LmtBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            val appCtx = context.applicationContext
            if (LmtBackgroundNotificationManager.isSessionActive(appCtx)) {
                LmtBackgroundNotificationManager.syncWorkerScheduling(appCtx)
            }
        }
    }
}
