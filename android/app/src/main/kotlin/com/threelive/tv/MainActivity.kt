package com.threelive.tv

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
class MainActivity : FlutterActivity() {
    private val channelName = "com.threelive.iptv/install"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
