package com.example.film_vibes

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.WindowManager
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

import io.flutter.FlutterInjector

import io.flutter.embedding.android.FlutterTextureView

class CustomOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (windowManager == null) {
            showOverlay()
        }
        return START_STICKY
    }

    private fun showOverlay() {
        // Start as foreground service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notification = android.app.Notification.Builder(this, createNotificationChannel())
                .setContentTitle("Film Vibes")
                .setContentText("Overlay active")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build()
            startForeground(1, notification)
        }

        // Initialize Flutter engine with overlay_main entrypoint
        flutterEngine = FlutterEngine(this)
        
        // Load the overlay_main entrypoint from lib/overlay_main.dart
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(this)
        loader.ensureInitializationComplete(this, null)
        
        flutterEngine!!.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "overlayMain"
            )
        )

        // Create FlutterView with TextureView for transparency
        flutterView = FlutterView(this, FlutterTextureView(this))
        flutterView!!.attachToFlutterEngine(flutterEngine!!)

        // Configure window layout parameters
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
            PixelFormat.TRANSLUCENT
        )

        // Manually set height to cover full screen including navigation bar
        val displayMetrics = android.util.DisplayMetrics()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        windowManager!!.defaultDisplay.getRealMetrics(displayMetrics)
        layoutParams.height = displayMetrics.heightPixels + 1000 // Add extra buffer to ensure coverage
        layoutParams.width = displayMetrics.widthPixels

        // Ensure FlutterView is transparent
        flutterView!!.setBackgroundColor(android.graphics.Color.TRANSPARENT)

        // Handle display cutouts (notch) for Android P+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            layoutParams.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        // Add view to window manager
        windowManager!!.addView(flutterView, layoutParams)
    }

    private fun createNotificationChannel(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "film_vibes_overlay"
            val channel = android.app.NotificationChannel(
                channelId,
                "Film Vibes Overlay",
                android.app.NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager.createNotificationChannel(channel)
            return channelId
        }
        return ""
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                // View might already be removed or not attached
                e.printStackTrace()
            }
            view.detachFromFlutterEngine()
        }
        flutterEngine?.destroy()
        flutterEngine = null
        flutterView = null
        windowManager = null
    }
}
