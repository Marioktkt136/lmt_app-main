package com.example.lmt

import android.Manifest
import android.app.Activity
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneId
import java.util.Calendar
import java.util.TimeZone
import kotlin.math.abs

/**
 * Coordinates Android background and lock-screen notification monitoring via
 * Firestore REST + custom team sound channels + JobScheduler / ForegroundService,
 * keeping alert deduplication and deep-link payloads in sync with Flutter Dart.
 */
object LmtBackgroundNotificationManager {
    const val CHANNEL_NAME = "com.example.lmt/background_sync"
    const val EXTRA_NOTIF_PAYLOAD = "lmt_notif_payload"
    const val FG_SERVICE_NOTIF_ID = 41027

    private const val PREFS_NAME = "lmt_bg_sync_prefs"
    private const val JOB_ID = 41026
    private const val KEY_LOGGED_IN = "is_logged_in"
    private const val KEY_USER_ID = "user_id"
    private const val KEY_API_KEY = "api_key"
    private const val KEY_PROJECT_ID = "project_id"
    private const val KEY_ID_TOKEN = "id_token"
    private const val KEY_TOKEN_TS = "token_ts_ms"
    private const val KEY_ALERTED_PREFIX = "alerted_ids_"
    private const val KEY_PENDING_NATIVE_PREFIX = "pending_native_ids_"

    private const val CHANNEL_NORMAL = "lmt_normal_notifications_v3"
    private const val CHANNEL_CALENDAR = "lmt_calendar_notifications_v3"
    private const val CHANNEL_CHAT = "lmt_chat_message_tone_v2"
    private const val CHANNEL_POST = "lmt_post_interactions_v2"
    private const val CHANNEL_REACT = "lmt_message_reacts_v2"
    const val CHANNEL_BG_SERVICE = "lmt_bg_service_quiet_v1"

    private const val MAX_ALERT_AGE_MS = 24L * 60L * 60L * 1000L
    private const val TOKEN_REFRESH_INTERVAL_MS = 45L * 60L * 1000L
    private const val MAX_STORED_ALERT_IDS = 300

    private val lock = Any()
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var isActivityResumed: Boolean = false

    @Volatile
    private var methodChannel: MethodChannel? = null

    @Volatile
    private var pendingLaunchPayload: String? = null

    fun attachChannel(channel: MethodChannel) {
        methodChannel = channel
    }

    fun detachChannel() {
        methodChannel = null
    }

    fun setActivityResumed(context: Context, resumed: Boolean) {
        isActivityResumed = resumed
        val appCtx = context.applicationContext
        if (isSessionActive(appCtx)) {
            syncWorkerScheduling(appCtx)
        }
    }

    fun isAppActivelyVisible(context: Context): Boolean {
        if (!isActivityResumed) return false
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        if (pm != null && !pm.isInteractive) return false
        val km = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        if (km != null && km.isKeyguardLocked) return false
        return true
    }

    fun handleLaunchIntent(intent: Intent?, fromNewIntent: Boolean) {
        val payload = intent?.getStringExtra(EXTRA_NOTIF_PAYLOAD)?.trim()
        if (payload.isNullOrEmpty()) return
        intent.removeExtra(EXTRA_NOTIF_PAYLOAD)
        if (fromNewIntent && methodChannel != null) {
            pendingLaunchPayload = null
            mainHandler.post {
                methodChannel?.invokeMethod("onBackgroundNotificationTapped", payload)
            }
        } else {
            pendingLaunchPayload = payload
        }
    }

    fun onMethodCall(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        val appCtx = activity.applicationContext
        when (call.method) {
            "syncSessionConfig" -> {
                val isLoggedIn = call.argument<Boolean>("isLoggedIn") ?: false
                val userId = (call.argument<String>("userId") ?: "").trim()
                val apiKey = (call.argument<String>("apiKey") ?: "").trim()
                val projectId = (call.argument<String>("projectId") ?: "").trim()
                val idToken = call.argument<String>("idToken")?.trim()
                val alertedIds = call.argument<List<String>>("alertedIds") ?: emptyList()

                synchronized(lock) {
                    val prefs = appCtx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val editor = prefs.edit()
                        .putBoolean(KEY_LOGGED_IN, isLoggedIn && userId.isNotEmpty())
                        .putString(KEY_USER_ID, userId)
                        .putString(KEY_API_KEY, apiKey)
                        .putString(KEY_PROJECT_ID, projectId)
                    if (!idToken.isNullOrEmpty()) {
                        editor.putString(KEY_ID_TOKEN, idToken)
                            .putLong(KEY_TOKEN_TS, System.currentTimeMillis())
                    } else if (!isLoggedIn) {
                        editor.remove(KEY_ID_TOKEN).remove(KEY_TOKEN_TS)
                    }
                    editor.apply()

                    if (isLoggedIn && userId.isNotEmpty() && alertedIds.isNotEmpty()) {
                        addIdsToPrefsSetLocked(prefs, "$KEY_ALERTED_PREFIX$userId", alertedIds)
                    }
                }

                syncWorkerScheduling(appCtx)
                result.success(null)
            }

            "recordAlertedIds" -> {
                val userId = (call.argument<String>("userId") ?: "").trim()
                val ids = call.argument<List<String>>("ids") ?: emptyList()
                if (userId.isNotEmpty() && ids.isNotEmpty()) {
                    synchronized(lock) {
                        val prefs = appCtx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        addIdsToPrefsSetLocked(prefs, "$KEY_ALERTED_PREFIX$userId", ids)
                    }
                }
                result.success(null)
            }

            "consumeNativeAlertedIds" -> {
                val userId = (call.argument<String>("userId") ?: "").trim()
                val consumed = ArrayList<String>()
                if (userId.isNotEmpty()) {
                    synchronized(lock) {
                        val prefs = appCtx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val key = "$KEY_PENDING_NATIVE_PREFIX$userId"
                        val existing = prefs.getStringSet(key, null)
                        if (!existing.isNullOrEmpty()) {
                            consumed.addAll(existing)
                            prefs.edit().remove(key).apply()
                        }
                    }
                }
                result.success(consumed)
            }

            "consumeLaunchPayload" -> {
                val payload = pendingLaunchPayload
                pendingLaunchPayload = null
                result.success(payload)
            }

            "isIgnoringBatteryOptimizations" -> {
                result.success(isIgnoringBatteryOptimizations(appCtx))
            }

            "requestIgnoreBatteryOptimizations" -> {
                openBatteryOptimizationSettings(activity)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    fun isSessionActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_LOGGED_IN, false) &&
            !prefs.getString(KEY_USER_ID, "").isNullOrBlank() &&
            !prefs.getString(KEY_API_KEY, "").isNullOrBlank() &&
            !prefs.getString(KEY_PROJECT_ID, "").isNullOrBlank()
    }

    fun syncWorkerScheduling(context: Context) {
        val appCtx = context.applicationContext
        ensureNotificationChannels(appCtx)
        if (!isSessionActive(appCtx)) {
            cancelPeriodicJob(appCtx)
            stopSyncService(appCtx)
            return
        }
        schedulePeriodicJob(appCtx)
        startSyncServiceSafely(appCtx)
    }

    fun startSyncServiceSafely(context: Context) {
        val appCtx = context.applicationContext
        if (!isSessionActive(appCtx)) return
        val serviceIntent = Intent(appCtx, LmtBackgroundSyncService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(appCtx, serviceIntent)
            } else {
                appCtx.startService(serviceIntent)
            }
        } catch (_: Exception) {
            // Android 12+ may defer background foreground-service start; JobScheduler covers it.
        }
    }

    fun stopSyncService(context: Context) {
        try {
            context.applicationContext.stopService(
                Intent(context.applicationContext, LmtBackgroundSyncService::class.java)
            )
        } catch (_: Exception) {
        }
    }

    fun schedulePeriodicJob(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler
            ?: return
        val component = ComponentName(context, LmtBackgroundSyncJobService::class.java)
        val builder = JobInfo.Builder(JOB_ID, component)
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
            .setPersisted(true)
            .setPeriodic(15L * 60L * 1000L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setRequiresBatteryNotLow(false)
            builder.setRequiresStorageNotLow(false)
        }
        try {
            scheduler.schedule(builder.build())
        } catch (_: Exception) {
        }
    }

    fun cancelPeriodicJob(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler
            ?: return
        try {
            scheduler.cancel(JOB_ID)
        } catch (_: Exception) {
        }
    }

    fun ensureNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return

        if (manager.getNotificationChannel(CHANNEL_BG_SERVICE) == null) {
            val quiet = NotificationChannel(
                CHANNEL_BG_SERVICE,
                "مزامنة الإشعارات بالخلفية",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "إبقاء استقبال إشعارات الفريق نشطاً عند قفل الشاشة"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            manager.createNotificationChannel(quiet)
        }

        ensureAlertChannel(
            context,
            manager,
            CHANNEL_NORMAL,
            "L.M.T Normal Notifications",
            "الإشعارات العامة للفريق والنظام والملفات",
            R.raw.normal_notifications
        )
        ensureAlertChannel(
            context,
            manager,
            CHANNEL_CALENDAR,
            "L.M.T Calendar Reminders",
            "تذكير مواعيد الفعاليات والبروفات",
            R.raw.calendar_notifications
        )
        ensureAlertChannel(
            context,
            manager,
            CHANNEL_CHAT,
            "L.M.T Chat Messages",
            "نغمة رسائل الشات والمحادثات الفورية",
            R.raw.chat_message_tone
        )
        ensureAlertChannel(
            context,
            manager,
            CHANNEL_POST,
            "L.M.T Post Interactions",
            "تفاعلات المنشورات والتعليقات والإعجابات",
            R.raw.post_interactions
        )
        ensureAlertChannel(
            context,
            manager,
            CHANNEL_REACT,
            "L.M.T Message Reactions",
            "تفاعلات الإيموجي على الرسائل في الشات",
            R.raw.message_reacts
        )
    }

    private fun ensureAlertChannel(
        context: Context,
        manager: NotificationManager,
        channelId: String,
        name: String,
        desc: String,
        rawResId: Int
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(channelId) != null) return
        val soundUri = rawSoundUri(context, rawResId)
        val audioAttrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            channelId,
            name,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = desc
            enableVibration(true)
            enableLights(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(soundUri, audioAttrs)
        }
        manager.createNotificationChannel(channel)
    }

    fun buildForegroundServiceNotification(context: Context): Notification {
        ensureNotificationChannels(context)
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            FG_SERVICE_NOTIF_ID,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(context, CHANNEL_BG_SERVICE)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("L.M.T App")
            .setContentText("استقبال الإشعارات الفورية نشط")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setOngoing(true)
            .setSilent(true)
            .setShowWhen(false)
            .setContentIntent(pendingIntent)
            .build()
    }

    /**
     * Fetches the latest team notifications via Firestore REST and triggers OS
     * lock-screen alerts for unseen notifications belonging to the signed-in user.
     *
     * Runs synchronously on a worker thread.
     */
    fun pollAndAlertIfNeeded(context: Context): Int {
        val appCtx = context.applicationContext
        if (isAppActivelyVisible(appCtx)) return 0

        val prefs = appCtx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_LOGGED_IN, false)) return 0
        val userId = (prefs.getString(KEY_USER_ID, "") ?: "").trim()
        val apiKey = (prefs.getString(KEY_API_KEY, "") ?: "").trim()
        val projectId = (prefs.getString(KEY_PROJECT_ID, "") ?: "").trim()
        if (userId.isEmpty() || apiKey.isEmpty() || projectId.isEmpty()) return 0

        var idToken = prefs.getString(KEY_ID_TOKEN, null)?.trim()
        val tokenTs = prefs.getLong(KEY_TOKEN_TS, 0L)
        if (idToken.isNullOrEmpty() || (System.currentTimeMillis() - tokenTs) > TOKEN_REFRESH_INTERVAL_MS) {
            idToken = refreshAnonymousToken(appCtx, apiKey) ?: idToken
        }
        if (idToken.isNullOrEmpty()) return 0

        var docs = fetchNotificationsViaRunQuery(projectId, idToken)
        if (docs == null) {
            // Token may have expired or been revoked; refresh once and retry.
            val refreshed = refreshAnonymousToken(appCtx, apiKey)
            if (!refreshed.isNullOrEmpty() && refreshed != idToken) {
                idToken = refreshed
                docs = fetchNotificationsViaRunQuery(projectId, idToken)
            }
        }
        if (docs == null) {
            docs = fetchNotificationsFallbackList(projectId, idToken)
        }
        if (docs.isNullOrEmpty()) return 0

        ensureNotificationChannels(appCtx)
        val knownIds: Set<String>
        synchronized(lock) {
            knownIds = (prefs.getStringSet("$KEY_ALERTED_PREFIX$userId", emptySet()) ?: emptySet())
                .toHashSet()
        }

        val newlyAlerted = ArrayList<String>()
        val nowMs = System.currentTimeMillis()

        for (doc in docs) {
            val id = doc.id.trim()
            if (id.isEmpty() || knownIds.contains(id)) continue
            if (doc.readByIds.contains(userId) || (doc.isRead && doc.readByIds.isEmpty())) continue
            if (doc.excludedMemberIds.contains(userId)) continue
            if (doc.targetMemberIds.isNotEmpty() && !doc.targetMemberIds.contains(userId)) continue
            if (doc.dateTimeMs <= 0L || abs(nowMs - doc.dateTimeMs) > MAX_ALERT_AGE_MS) continue

            if (postLockScreenNotification(appCtx, doc)) {
                newlyAlerted.add(id)
            }
        }

        if (newlyAlerted.isNotEmpty()) {
            synchronized(lock) {
                addIdsToPrefsSetLocked(prefs, "$KEY_ALERTED_PREFIX$userId", newlyAlerted)
                addIdsToPrefsSetLocked(prefs, "$KEY_PENDING_NATIVE_PREFIX$userId", newlyAlerted)
            }
        }
        return newlyAlerted.size
    }

    private fun refreshAnonymousToken(context: Context, apiKey: String): String? {
        var conn: HttpURLConnection? = null
        return try {
            val url = URL("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey")
            conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 8000
                readTimeout = 8000
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            }
            OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { writer ->
                writer.write("""{"returnSecureToken":true}""")
            }
            if (conn.responseCode !in 200..299) return null
            val body = BufferedReader(InputStreamReader(conn.inputStream, Charsets.UTF_8)).use {
                it.readText()
            }
            val token = JSONObject(body).optString("idToken", "").trim()
            if (token.isEmpty()) return null
            synchronized(lock) {
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit()
                    .putString(KEY_ID_TOKEN, token)
                    .putLong(KEY_TOKEN_TS, System.currentTimeMillis())
                    .apply()
            }
            token
        } catch (_: Exception) {
            null
        } finally {
            conn?.disconnect()
        }
    }

    private fun fetchNotificationsViaRunQuery(
        projectId: String,
        idToken: String
    ): List<ParsedNotification>? {
        var conn: HttpURLConnection? = null
        return try {
            val url = URL(
                "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery"
            )
            conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 8000
                readTimeout = 8000
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                setRequestProperty("Authorization", "Bearer $idToken")
            }
            val queryJson = """
                {
                  "structuredQuery": {
                    "from": [{"collectionId": "notifications"}],
                    "orderBy": [{"field": {"fieldPath": "dateTime"}, "direction": "DESCENDING"}],
                    "limit": 25
                  }
                }
            """.trimIndent()
            OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { writer ->
                writer.write(queryJson)
            }
            val code = conn.responseCode
            if (code == 401 || code == 403 || code !in 200..299) {
                return null
            }
            val body = BufferedReader(InputStreamReader(conn.inputStream, Charsets.UTF_8)).use {
                it.readText()
            }
            val array = JSONArray(body)
            val result = ArrayList<ParsedNotification>()
            for (i in 0 until array.length()) {
                val entry = array.optJSONObject(i) ?: continue
                val doc = entry.optJSONObject("document") ?: continue
                parseFirestoreDocument(doc)?.let { result.add(it) }
            }
            result
        } catch (_: Exception) {
            null
        } finally {
            conn?.disconnect()
        }
    }

    private fun fetchNotificationsFallbackList(
        projectId: String,
        idToken: String
    ): List<ParsedNotification>? {
        var conn: HttpURLConnection? = null
        return try {
            val url = URL(
                "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/notifications?pageSize=60"
            )
            conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 8000
                readTimeout = 8000
                setRequestProperty("Authorization", "Bearer $idToken")
            }
            if (conn.responseCode !in 200..299) return null
            val body = BufferedReader(InputStreamReader(conn.inputStream, Charsets.UTF_8)).use {
                it.readText()
            }
            val docsArray = JSONObject(body).optJSONArray("documents") ?: return emptyList()
            val result = ArrayList<ParsedNotification>()
            for (i in 0 until docsArray.length()) {
                val doc = docsArray.optJSONObject(i) ?: continue
                parseFirestoreDocument(doc)?.let { result.add(it) }
            }
            result
        } catch (_: Exception) {
            null
        } finally {
            conn?.disconnect()
        }
    }

    private fun parseFirestoreDocument(doc: JSONObject): ParsedNotification? {
        val fields = doc.optJSONObject("fields") ?: return null
        val fallbackId = doc.optString("name", "").substringAfterLast('/')
        val id = fsString(fields, "id").ifEmpty { fallbackId }
        val title = fsString(fields, "title")
        val description = fsString(fields, "description")
        if (id.isEmpty() || (title.isEmpty() && description.isEmpty())) return null

        val dateStr = fsString(fields, "dateTime")
        val dateMs = parseIso8601ToEpochMs(dateStr)
        val category = fsString(fields, "category").ifEmpty { "system" }
        val rawTone = fsString(fields, "tone")
        val tone = when {
            rawTone.isNotEmpty() -> rawTone
            category == "calendar" -> "calendar"
            category == "chat" -> "chatMessage"
            else -> "normal"
        }

        return ParsedNotification(
            id = id,
            title = title.ifEmpty { "L.M.T App" },
            description = description,
            dateTimeMs = dateMs,
            category = category,
            isRead = fsBoolean(fields, "isRead"),
            targetTabIndex = fsInt(fields, "targetTabIndex"),
            targetGroupId = fsStringOrNull(fields, "targetGroupId"),
            targetEventId = fsStringOrNull(fields, "targetEventId"),
            targetRoute = fsStringOrNull(fields, "targetRoute"),
            targetMemberIds = fsStringArray(fields, "targetMemberIds"),
            excludedMemberIds = fsStringArray(fields, "excludedMemberIds"),
            readByIds = fsStringArray(fields, "readByIds"),
            tone = tone
        )
    }

    private fun postLockScreenNotification(context: Context, item: ParsedNotification): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        val nmCompat = NotificationManagerCompat.from(context)
        if (!nmCompat.areNotificationsEnabled()) return false

        val (channelId, rawResId) = when (item.tone) {
            "calendar" -> Pair(CHANNEL_CALENDAR, R.raw.calendar_notifications)
            "chatMessage" -> Pair(CHANNEL_CHAT, R.raw.chat_message_tone)
            "postInteractions" -> Pair(CHANNEL_POST, R.raw.post_interactions)
            "messageReacts" -> Pair(CHANNEL_REACT, R.raw.message_reacts)
            else -> Pair(CHANNEL_NORMAL, R.raw.normal_notifications)
        }

        val payloadJson = JSONObject().apply {
            put("notifId", item.id)
            item.targetTabIndex?.let { put("tab", it) }
            item.targetGroupId?.let { put("groupId", it) }
            item.targetEventId?.let { put("eventId", it) }
            item.targetRoute?.let { put("route", it) }
        }.toString()

        val notifId = item.id.hashCode() and 0x7FFFFFFF
        val tapIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.lmt.NOTIF_TAP_$notifId"
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_NOTIF_PAYLOAD, payloadJson)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            notifId,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val soundUri = rawSoundUri(context, rawResId)
        val largeIcon = try {
            BitmapFactory.decodeResource(context.resources, R.drawable.ic_notification_large)
        } catch (_: Exception) {
            null
        }
        val notifCategory = when (item.category) {
            "chat" -> NotificationCompat.CATEGORY_MESSAGE
            "calendar" -> NotificationCompat.CATEGORY_EVENT
            else -> NotificationCompat.CATEGORY_SOCIAL
        }

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(0xFF1E88E5.toInt())
            .setContentTitle(item.title)
            .setContentText(item.description)
            .setStyle(NotificationCompat.BigTextStyle().bigText(item.description))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(notifCategory)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(soundUri)
            .setContentIntent(pendingIntent)

        if (largeIcon != null) {
            builder.setLargeIcon(largeIcon)
        }

        return try {
            nmCompat.notify(notifId, builder.build())
            true
        } catch (_: SecurityException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun rawSoundUri(context: Context, rawResId: Int): Uri {
        return Uri.parse(
            "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${context.packageName}/$rawResId"
        )
    }

    private fun addIdsToPrefsSetLocked(
        prefs: android.content.SharedPreferences,
        key: String,
        newIds: Collection<String>
    ) {
        val current = (prefs.getStringSet(key, emptySet()) ?: emptySet()).toMutableList()
        for (id in newIds) {
            val trimmed = id.trim()
            if (trimmed.isNotEmpty() && !current.contains(trimmed)) {
                current.add(trimmed)
            }
        }
        val bounded = if (current.size > MAX_STORED_ALERT_IDS) {
            current.subList(current.size - MAX_STORED_ALERT_IDS, current.size).toSet()
        } else {
            current.toSet()
        }
        prefs.edit().putStringSet(key, bounded).apply()
    }

    private fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        return try {
            pm.isIgnoringBatteryOptimizations(context.packageName)
        } catch (_: Exception) {
            true
        }
    }

    private fun openBatteryOptimizationSettings(activity: Activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
            activity.startActivity(intent)
        } catch (_: Exception) {
            try {
                activity.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
            }
        }
    }

    private fun fsString(fields: JSONObject, key: String): String {
        val obj = fields.optJSONObject(key) ?: return ""
        return obj.optString("stringValue", "").trim()
    }

    private fun fsStringOrNull(fields: JSONObject, key: String): String? {
        val s = fsString(fields, key)
        return s.ifEmpty { null }
    }

    private fun fsBoolean(fields: JSONObject, key: String): Boolean {
        val obj = fields.optJSONObject(key) ?: return false
        return obj.optBoolean("booleanValue", false)
    }

    private fun fsInt(fields: JSONObject, key: String): Int? {
        val obj = fields.optJSONObject(key) ?: return null
        val raw = obj.optString("integerValue", "")
        return raw.toIntOrNull()
    }

    private fun fsStringArray(fields: JSONObject, key: String): List<String> {
        val obj = fields.optJSONObject(key) ?: return emptyList()
        val array = obj.optJSONObject("arrayValue")?.optJSONArray("values") ?: return emptyList()
        val list = ArrayList<String>(array.length())
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            val value = item.optString("stringValue", "").trim()
            if (value.isNotEmpty()) list.add(value)
        }
        return list
    }

    private fun parseIso8601ToEpochMs(raw: String): Long {
        if (raw.isEmpty()) return 0L
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                return Instant.parse(raw).toEpochMilli()
            } catch (_: Exception) {
            }
            try {
                return OffsetDateTime.parse(raw).toInstant().toEpochMilli()
            } catch (_: Exception) {
            }
            try {
                return LocalDateTime.parse(raw).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
            } catch (_: Exception) {
            }
        }
        val match = Regex("""^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})""").find(raw)
            ?: return 0L
        val year = match.groupValues[1].toIntOrNull() ?: return 0L
        val month = (match.groupValues[2].toIntOrNull() ?: return 0L) - 1
        val day = match.groupValues[3].toIntOrNull() ?: return 0L
        val hour = match.groupValues[4].toIntOrNull() ?: return 0L
        val min = match.groupValues[5].toIntOrNull() ?: return 0L
        val sec = match.groupValues[6].toIntOrNull() ?: return 0L
        val tz = if (raw.endsWith("Z")) TimeZone.getTimeZone("UTC") else TimeZone.getDefault()
        return Calendar.getInstance(tz).apply {
            set(year, month, day, hour, min, sec)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private data class ParsedNotification(
        val id: String,
        val title: String,
        val description: String,
        val dateTimeMs: Long,
        val category: String,
        val isRead: Boolean,
        val targetTabIndex: Int?,
        val targetGroupId: String?,
        val targetEventId: String?,
        val targetRoute: String?,
        val targetMemberIds: List<String>,
        val excludedMemberIds: List<String>,
        val readByIds: List<String>,
        val tone: String
    )
}
