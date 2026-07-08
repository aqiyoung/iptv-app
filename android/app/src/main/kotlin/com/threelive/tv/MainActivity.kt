package com.threelive.tv

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val channelName = "com.threelive.iptv/install"
    private val fallbackChannelName = "com.threelive.iptv/fallback_player"
    private val libmpvCheckChannelName = "com.threelive.iptv/check_libmpv"
    private val pipChannelName = "com.threelive.iptv/pip"
    private val TAG = "SanyeliveMain"
    private val REQUEST_PERMISSIONS = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        installNativeCrashHandler()
        requestStoragePermissions()
        super.onCreate(savedInstanceState)
    }

    // v0.3.11: 按 Home 键 → 自动进入 PiP
    override fun onUserLeaveHint() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                enterPictureInPictureMode()
            } catch (e: Exception) {
                Log.e(TAG, "onUserLeaveHint: ${e.message}")
            }
        }
        super.onUserLeaveHint()
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    private fun requestStoragePermissions() {
        val perms = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            perms.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            perms.add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES)
                != PackageManager.PERMISSION_GRANTED
            ) {
                perms.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!android.os.Environment.isExternalStorageManager()) {
                try {
                    val intent = Intent(android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                } catch (e: Exception) {
                    Log.w(TAG, "Cannot open storage settings: ${e.message}")
                }
            }
        }
        if (perms.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, perms.toTypedArray(), REQUEST_PERMISSIONS)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        installNativeCrashHandler()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("ARG_ERROR", "path is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installApk(path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fallbackChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        result.success(false)
                    }
                    "stop" -> {
                        result.success(null)
                    }
                    "pause" -> {
                        result.success(null)
                    }
                    "resume" -> {
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, libmpvCheckChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkLibmpv" -> {
                        try {
                            System.loadLibrary("mpv")
                            result.success(true)
                        } catch (e: UnsatisfiedLinkError) {
                            Log.w(TAG, "libmpv.so не доступен: ${e.message}")
                            result.success(false)
                        } catch (e: Throwable) {
                            Log.e(TAG, "libmpv.so ошибка загрузки: ${e.message}")
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // v0.3.11: PiP (画中画) 控制通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enterPip" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                val ret = enterPictureInPictureMode()
                                result.success(ret)
                            } catch (e: Exception) {
                                Log.e(TAG, "enterPip failed: ${e.message}")
                                result.error("PIP_ERROR", e.message, null)
                            }
                        } else {
                            result.error("PIP_ERROR", "Android 8.0+ required", null)
                        }
                    }
                    "isInPip" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            result.success(isInPictureInPictureMode())
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installNativeCrashHandler() {
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val crashDir = filesDir
                if (crashDir != null) {
                    val crashFile = File(crashDir, "native_crash.log")
                    val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
                    val sw = StringWriter()
                    throwable.printStackTrace(PrintWriter(sw))
                    val logEntry = "$timestamp: [${thread.name}] ${throwable.javaClass.name}: ${throwable.message}\n$sw\n"
                    crashFile.appendText(logEntry)
                    Log.e(TAG, "Native crash logged to ${crashFile.absolutePath}", throwable)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to write native crash log", e)
            }
            try {
                val sw2 = StringWriter()
                throwable.printStackTrace(PrintWriter(sw2))
                val intent = Intent(this, CrashActivity::class.java).apply {
                    putExtra("error", "${throwable.javaClass.name}: ${throwable.message}")
                    putExtra("stack", sw2.toString())
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                startActivity(intent)
                Thread.sleep(2000)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to launch CrashActivity", e)
            }
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("file not found: $path")
        }

        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file,
            )
        } else {
            Uri.fromFile(file)
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(intent)
    }
}
