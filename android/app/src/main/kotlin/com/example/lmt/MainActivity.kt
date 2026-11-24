package com.example.lmt

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.lmt/native_media"
    private val MIC_PERMISSION_REQUEST_CODE = 2026
    private val FILE_PICKER_REQUEST_CODE = 2027
    private val CAMERA_PERMISSION_REQUEST_CODE = 2028
    private val CAMERA_CAPTURE_REQUEST_CODE = 2029

    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentRecordingPath: String? = null
    private var currentPlayingPath: String? = null
    private var pendingMicResult: MethodChannel.Result? = null
    private var pendingFilePickerResult: MethodChannel.Result? = null
    private var pendingCameraResult: MethodChannel.Result? = null
    private var pendingCameraFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        LmtBackgroundNotificationManager.handleLaunchIntent(intent, fromNewIntent = false)
        val bgSyncChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LmtBackgroundNotificationManager.CHANNEL_NAME
        )
        LmtBackgroundNotificationManager.attachChannel(bgSyncChannel)
        bgSyncChannel.setMethodCallHandler { call, result ->
            LmtBackgroundNotificationManager.onMethodCall(this, call, result)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDeviceFile" -> {
                        val pickerType = call.argument<String>("type") ?: "any"
                        val allowedExtensions = call.argument<List<String>>("allowedExtensions")
                        launchSystemFilePicker(pickerType, allowedExtensions, result)
                    }

                    "captureCameraPhoto" -> {
                        launchCameraWithPermission(result)
                    }

                    "requestMicPermission" -> {
                        if (hasMicPermission()) {
                            result.success(true)
                        } else {
                            pendingMicResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.RECORD_AUDIO),
                                MIC_PERMISSION_REQUEST_CODE
                            )
                        }
                    }

                    "startVoiceRecording" -> {
                        if (!hasMicPermission()) {
                            result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
                        } else {
                            try {
                                val path = startRecordingInternal()
                                result.success(path)
                            } catch (e: Exception) {
                                result.error("RECORD_ERROR", e.message, null)
                            }
                        }
                    }

                    "stopVoiceRecording" -> {
                        try {
                            val path = stopRecordingInternal()
                            result.success(path)
                        } catch (e: Exception) {
                            result.error("STOP_ERROR", e.message, null)
                        }
                    }

                    "cancelVoiceRecording" -> {
                        cancelRecordingInternal()
                        result.success(true)
                    }

                    "playVoiceNote" -> {
                        val path = call.argument<String>("path")
                        val speed = call.argument<Double>("speed") ?: 1.0
                        val positionMs = call.argument<Int>("positionMs")
                        if (path.isNullOrEmpty()) {
                            result.error("INVALID_PATH", "Audio path is empty", null)
                        } else {
                            try {
                                playAudioInternal(path, speed.toFloat(), positionMs)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("PLAY_ERROR", e.message, null)
                            }
                        }
                    }

                    "pauseVoiceNote" -> {
                        pauseAudioInternal()
                        result.success(true)
                    }

                    "seekVoiceNote" -> {
                        val positionMs = call.argument<Int>("positionMs") ?: 0
                        seekAudioInternal(positionMs)
                        result.success(true)
                    }

                    "setVoicePlaybackSpeed" -> {
                        val speed = call.argument<Double>("speed") ?: 1.0
                        setAudioSpeedInternal(speed.toFloat())
                        result.success(true)
                    }

                    "stopVoiceNote" -> {
                        stopAudioInternal()
                        result.success(true)
                    }

                    "saveFileToPublicDownloads" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName") ?: "LMT_File.txt"
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        if (sourcePath.isNullOrEmpty()) {
                            result.error("INVALID_SOURCE", "Source path is empty", null)
                        } else {
                            try {
                                val publicPath = saveToDownloadsInternal(sourcePath, fileName, mimeType)
                                result.success(publicPath)
                            } catch (e: Exception) {
                                result.error("DOWNLOAD_ERROR", e.message, null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun launchSystemFilePicker(
        pickerType: String,
        allowedExtensions: List<String>?,
        result: MethodChannel.Result
    ) {
        try {
            pendingFilePickerResult = result

            // Open the phone's Gallery / Photo Picker directly for image, video, and media picks.
            if (pickerType == "image" || pickerType == "video" || pickerType == "media") {
                val galleryIntent = if (Build.VERSION.SDK_INT >= 33) {
                    Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                        when (pickerType) {
                            "image" -> type = "image/*"
                            "video" -> type = "video/*"
                            // Leaving type unset on API 33+ shows BOTH images & videos in Photo Picker.
                        }
                    }
                } else {
                    when (pickerType) {
                        "video" -> Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI).apply {
                            type = "video/*"
                        }
                        "media" -> Intent(Intent.ACTION_PICK).apply {
                            type = "image/* video/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
                        }
                        else -> Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
                            type = "image/*"
                        }
                    }
                }
                @Suppress("DEPRECATION")
                startActivityForResult(galleryIntent, FILE_PICKER_REQUEST_CODE)
                return
            }

            // Open the Files / Document browser for general files or custom extensions.
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                if (pickerType == "custom" && !allowedExtensions.isNullOrEmpty()) {
                    val mimeTypes = allowedExtensions.mapNotNull { ext ->
                        MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.lowercase())
                    }.distinct().toTypedArray()
                    if (mimeTypes.isNotEmpty()) {
                        putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
                    }
                }
            }
            @Suppress("DEPRECATION")
            startActivityForResult(intent, FILE_PICKER_REQUEST_CODE)
        } catch (e: Exception) {
            pendingFilePickerResult = null
            result.error("PICKER_ERROR", e.message, null)
        }
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun launchCameraWithPermission(result: MethodChannel.Result) {
        if (hasCameraPermission()) {
            launchCameraCapture(result)
        } else {
            pendingCameraResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                CAMERA_PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun launchCameraCapture(result: MethodChannel.Result) {
        try {
            val dir = File(cacheDir, "camera_photos")
            if (!dir.exists()) {
                dir.mkdirs()
            }
            val photoFile = File(dir, "lmt_cam_${System.currentTimeMillis()}.jpg")
            pendingCameraFile = photoFile
            pendingCameraResult = result
            val photoUri = FileProvider.getUriForFile(
                this,
                "$packageName.lmt_camera_provider",
                photoFile
            )
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, photoUri)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            @Suppress("DEPRECATION")
            startActivityForResult(intent, CAMERA_CAPTURE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingCameraFile = null
            pendingCameraResult = null
            result.error("CAMERA_ERROR", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == FILE_PICKER_REQUEST_CODE) {
            val callback = pendingFilePickerResult
            pendingFilePickerResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                try {
                    val uri = data.data!!
                    val fileMap = copyUriToLocalCache(uri)
                    callback?.success(fileMap)
                } catch (e: Exception) {
                    callback?.error("COPY_ERROR", e.message, null)
                }
            } else {
                callback?.success(null)
            }
        } else if (requestCode == CAMERA_CAPTURE_REQUEST_CODE) {
            val callback = pendingCameraResult
            val file = pendingCameraFile
            pendingCameraResult = null
            pendingCameraFile = null
            if (resultCode == Activity.RESULT_OK && file != null && file.exists() && file.length() > 0) {
                callback?.success(
                    mapOf(
                        "name" to file.name,
                        "path" to file.absolutePath,
                        "size" to file.length().toInt()
                    )
                )
            } else {
                file?.delete()
                callback?.success(null)
            }
        }
    }

    private fun copyUriToLocalCache(uri: Uri): Map<String, Any> {
        var displayName = "picked_${System.currentTimeMillis()}"
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    val rawName = cursor.getString(nameIndex)
                    if (!rawName.isNullOrBlank()) {
                        displayName = rawName
                    }
                }
            }
        }

        val dir = File(cacheDir, "picked_files")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        val safeName = displayName.replace(Regex("[\\\\/:*?\"<>|]"), "_")
        val destFile = File(dir, "${System.currentTimeMillis()}_$safeName")

        contentResolver.openInputStream(uri)?.use { inStream ->
            FileOutputStream(destFile).use { outStream ->
                inStream.copyTo(outStream)
            }
        }

        return mapOf(
            "name" to displayName,
            "path" to destFile.absolutePath,
            "size" to destFile.length().toInt()
        )
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == MIC_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingMicResult?.success(granted)
            pendingMicResult = null
        } else if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            val callback = pendingCameraResult
            pendingCameraResult = null
            if (granted && callback != null) {
                launchCameraCapture(callback)
            } else {
                callback?.error("PERMISSION_DENIED", "Camera permission denied", null)
            }
        }
    }

    private fun startRecordingInternal(): String {
        stopRecordingInternal()
        val dir = File(filesDir, "voice_notes")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        val outFile = File(dir, "vn_${System.currentTimeMillis()}.m4a")
        currentRecordingPath = outFile.absolutePath

        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        recorder.setAudioEncodingBitRate(128000)
        recorder.setAudioSamplingRate(44100)
        recorder.setOutputFile(outFile.absolutePath)
        recorder.prepare()
        recorder.start()
        mediaRecorder = recorder
        return outFile.absolutePath
    }

    private fun stopRecordingInternal(): String? {
        val path = currentRecordingPath
        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
        } catch (_: Exception) {
        } finally {
            mediaRecorder = null
        }
        return path
    }

    private fun cancelRecordingInternal() {
        val path = stopRecordingInternal()
        if (!path.isNullOrEmpty()) {
            try {
                File(path).delete()
            } catch (_: Exception) {
            }
        }
        currentRecordingPath = null
    }

    private fun playAudioInternal(path: String, speed: Float, positionMs: Int?) {
        val existing = mediaPlayer
        if (existing != null && currentPlayingPath == path) {
            if (positionMs != null) {
                existing.seekTo(positionMs)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                try {
                    existing.playbackParams = existing.playbackParams.setSpeed(speed)
                } catch (_: Exception) {
                }
            }
            if (!existing.isPlaying) {
                existing.start()
            }
            return
        }

        stopAudioInternal()
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("Audio file does not exist at $path")
        }
        val player = MediaPlayer()
        player.setDataSource(path)
        player.prepare()
        if (positionMs != null && positionMs > 0) {
            player.seekTo(positionMs)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                player.playbackParams = player.playbackParams.setSpeed(speed)
            } catch (_: Exception) {
            }
        }
        player.start()
        player.setOnCompletionListener {
            it.release()
            if (mediaPlayer == it) {
                mediaPlayer = null
                currentPlayingPath = null
            }
        }
        mediaPlayer = player
        currentPlayingPath = path
    }

    private fun pauseAudioInternal() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.pause()
                }
            }
        } catch (_: Exception) {
        }
    }

    private fun seekAudioInternal(positionMs: Int) {
        try {
            mediaPlayer?.seekTo(positionMs)
        } catch (_: Exception) {
        }
    }

    private fun setAudioSpeedInternal(speed: Float) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                mediaPlayer?.let { player ->
                    if (player.isPlaying) {
                        player.playbackParams = player.playbackParams.setSpeed(speed)
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    private fun stopAudioInternal() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
        } catch (_: Exception) {
        } finally {
            mediaPlayer = null
            currentPlayingPath = null
        }
    }

    private fun saveToDownloadsInternal(
        sourcePath: String,
        fileName: String,
        mimeType: String
    ): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            throw IllegalArgumentException("Source file not found: $sourcePath")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/LMT")
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri != null) {
                resolver.openOutputStream(uri)?.use { outStream ->
                    FileInputStream(sourceFile).use { inStream ->
                        inStream.copyTo(outStream)
                    }
                }
                return "/storage/emulated/0/Download/LMT/$fileName"
            }
        }

        val publicDownloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        val lmtDir = File(publicDownloads, "LMT")
        if (!lmtDir.exists()) {
            lmtDir.mkdirs()
        }
        val destFile = File(lmtDir, fileName)
        FileInputStream(sourceFile).use { inStream ->
            FileOutputStream(destFile).use { outStream ->
                inStream.copyTo(outStream)
            }
        }
        return destFile.absolutePath
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        LmtBackgroundNotificationManager.handleLaunchIntent(intent, fromNewIntent = true)
    }

    override fun onResume() {
        super.onResume()
        LmtBackgroundNotificationManager.setActivityResumed(this, true)
    }

    override fun onPause() {
        LmtBackgroundNotificationManager.setActivityResumed(this, false)
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        LmtBackgroundNotificationManager.detachChannel()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
