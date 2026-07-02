package com.threelive.tv.pip

import android.content.Context
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.WindowManager
import android.widget.FrameLayout

/// v0.3.10.22: PiP 原生视频播放器 — 渲染到独立 SurfaceView
/// SurfaceView 由 WindowManager 管理, 不依赖 Flutter Activity 生命周期
class PipPlayerManager(private val context: Context) {

    private var mediaPlayer: MediaPlayer? = null
    private var surfaceView: SurfaceView? = null
    private var windowManager: WindowManager? = null
    private var isPlaying = false
    private var currentUrl: String? = null

    companion object {
        private const val TAG = "PipPlayerManager"
    }

    /// 开始 PiP 播放 (隐藏 Flutter, 显示原生 SurfaceView)
    fun start(url: String) {
        if (isPlaying && currentUrl == url) return
        Log.d(TAG, "start: $url")
        stop() // 先清理旧的

        currentUrl = url
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        try {
            // 创建 SurfaceView
            surfaceView = SurfaceView(context).apply {
                setBackgroundColor(android.graphics.Color.BLACK)
                holder.setFormat(PixelFormat.OPAQUE)
                holder.addCallback(object : SurfaceHolder.Callback {
                    override fun surfaceCreated(holder: SurfaceHolder) {
                        Log.d(TAG, "surfaceCreated")
                        initPlayer(url, holder)
                    }

                    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                        Log.d(TAG, "surfaceChanged: ${width}x${height}")
                    }

                    override fun surfaceDestroyed(holder: SurfaceHolder) {
                        Log.d(TAG, "surfaceDestroyed")
                    }
                })
            }

            // 添加到 WindowManager (TYPE_APPLICATION_OVERLAY 可以在 Flutter 上面显示)
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.OPAQUE
            ).apply {
                gravity = Gravity.TOP or Gravity.START
            }

            windowManager?.addView(surfaceView, params)
            isPlaying = true
            Log.d(TAG, "PipPlayer started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "start failed: ${e.message}")
            isPlaying = false
        }
    }

    /// 初始化 MediaPlayer
    private fun initPlayer(url: String, holder: SurfaceHolder) {
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioStreamType(AudioManager.STREAM_MUSIC)
                setDataSource(url)
                setSurface(holder.surface)
                setScreenOnWhilePlaying(true)
                setOnPreparedListener { mp ->
                    Log.d(TAG, "MediaPlayer prepared, starting playback")
                    mp.start()
                }
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                    true
                }
                setOnCompletionListener {
                    Log.d(TAG, "MediaPlayer completed")
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            Log.e(TAG, "initPlayer failed: ${e.message}")
        }
    }

    /// 停止 PiP 播放
    fun stop() {
        Log.d(TAG, "stop")
        isPlaying = false

        try {
            mediaPlayer?.stop()
        } catch (e: Exception) { Log.d(TAG, "stop: mediaPlayer.stop error: ${e.message}") }
        try {
            mediaPlayer?.release()
        } catch (e: Exception) { Log.d(TAG, "stop: mediaPlayer.release error: ${e.message}") }
        mediaPlayer = null

        try {
            surfaceView?.holder?.surface?.release()
        } catch (e: Exception) { Log.d(TAG, "stop: surface.release error: ${e.message}") }

        try {
            if (surfaceView != null && windowManager != null) {
                windowManager?.removeView(surfaceView)
            }
        } catch (e: Exception) {
            Log.e(TAG, "removeView failed: ${e.message}")
        }
        surfaceView = null
        currentUrl = null
    }

    /// 是否正在播放
    fun isPlaying(): Boolean = isPlaying
}
