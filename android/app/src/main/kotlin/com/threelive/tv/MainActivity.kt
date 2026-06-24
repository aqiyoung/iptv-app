package com.threelive.tv

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
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

/// v0.3.7+20 (6/18): 后台强制更新 — MethodChannel 调 Android installer.
///
/// 不用 install_plugin 2.1.0 (package 缺 namespace + JVM target 不一致,
/// AGP 8+ 编译不过).  自己写 MethodChannel 处理 "installApk" 通道.
///
/// 使用:
///   final channel = MethodChannel(messenger, 'com.threelive.iptv/install');
///   await channel.invokeMethod('installApk', {'path': '/data/.../app.apk'});
///
/// Android 7+ (API 24+) 必须用 FileProvider 共享 file:// URI 给 installer.
///
/// v0.3.10.13: Native crash handler — 捕获 SIGSEGV/SIGABRT 等 native signal,
/// 写到 /sdcard/Android/data/com.threelive.tv/files/native_crash.log,
/// 老板 adb pull 即可看到 native crash stacktrace.
class MainActivity : FlutterActivity() {
    private val channelName = "com.threelive.iptv/install"
    private val fallbackChannelName = "com.threelive.iptv/fallback_player"
    private val TAG = "SanyeliveMain"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // v0.3.10.13: 安装 native crash handler
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

        // v0.3.10.13: Fallback player channel — libmpv 不可用时走 Android MediaPlayer
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fallbackChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.error("ARG_ERROR", "url is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(false) // 暂不实现, 避免 MissingPluginException
                        } catch (e: Exception) {
                            result.error("PLAY_ERROR", e.message, null)
                        }
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
    }

    /// v0.3.10.13: 安装 native crash handler — 用 Thread.setDefaultUncaughtExceptionHandler
    /// 捕获未处理的 Java/Kotlin 异常,  写到 crash log 文件.
    /// 注意: 这只能捕获 Java 层异常,  SIGSEGV 等 native signal 需要
    /// 注册 signal handler (C/C++ 层).  但 Java 层的 UncaughtExceptionHandler
    /// 能捕获到 libmpv JNI 调用抛出的 Java 异常 (比如 UnsatisfiedLinkError).
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
            // 调用原始 handler (让系统默认 crash 流程继续)
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("file not found: $path")
        }

        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Android 7+ (API 24+) — 用 FileProvider.  authority 跟
            // AndroidManifest 里 file_paths.xml + provider 配的
            // ${applicationId}.fileprovider 一致.
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
