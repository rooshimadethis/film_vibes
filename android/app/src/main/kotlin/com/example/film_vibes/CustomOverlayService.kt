package com.example.film_vibes

import android.app.Service
import android.content.Context
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
import io.flutter.plugin.common.MethodChannel

class CustomOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null

    override fun onBind(intent: Intent?): IBinder? = null

    private var initialBaseOpacity = 0.25
    private var initialGrainOpacity = 0.40
    private var initialTintOpacity = 0.10

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            initialBaseOpacity = intent.getDoubleExtra("baseOpacity", 0.25)
            initialGrainOpacity = intent.getDoubleExtra("grainOpacity", 0.40)
            initialTintOpacity = intent.getDoubleExtra("tintOpacity", 0.10)
        }

        if (windowManager == null) {
            try {
                showOverlay()
            } catch (e: Exception) {
                e.printStackTrace()
                stopSelf()
            }
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
        // Use applicationContext to avoid context leaks and ensure stable initialization
        flutterEngine = FlutterEngine(applicationContext)
        
        // Load the overlay_main entrypoint from lib/overlay_main.dart
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        
        flutterEngine!!.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "overlayMain"
            )
        )

        // Create FlutterView with TextureView for transparency
        flutterView = FlutterView(this, FlutterTextureView(this))
        // Ensure transparency is set before attaching
        flutterView!!.setBackgroundColor(android.graphics.Color.TRANSPARENT)
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
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        wm.defaultDisplay.getRealMetrics(displayMetrics)
        layoutParams.height = displayMetrics.heightPixels + 1000 // Add extra buffer to ensure coverage
        layoutParams.width = displayMetrics.widthPixels

        // Handle display cutouts (notch) for Android P+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            layoutParams.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        // Add view to window manager
        wm.addView(flutterView, layoutParams)
        
        // Only assign windowManager if addView succeeded
        windowManager = wm

        // Setup MethodChannel to handle getInitialSettings
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, "film_vibes/overlay_control").setMethodCallHandler { call, result ->
                if (call.method == "getInitialSettings") {
                    result.success(mapOf(
                        "baseOpacity" to initialBaseOpacity,
                        "grainOpacity" to initialGrainOpacity,
                        "tintOpacity" to initialTintOpacity
                    ))
                } else {
                    result.notImplemented()
                }
            }
        }
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

    private val updateReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.film_vibes.UPDATE_OVERLAY") {
                android.util.Log.d("CustomOverlayService", "Received update broadcast")
                val baseOpacity = intent.getDoubleExtra("baseOpacity", 0.25)
                val grainOpacity = intent.getDoubleExtra("grainOpacity", 0.40)
                val tintOpacity = intent.getDoubleExtra("tintOpacity", 0.10)

                if (flutterEngine == null) {
                    android.util.Log.e("CustomOverlayService", "flutterEngine is NULL")
                } else {
                    android.util.Log.d("CustomOverlayService", "Sending to Flutter: base=$baseOpacity")
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, "film_vibes/overlay_control")
                            .invokeMethod("updateSettings", mapOf(
                                "baseOpacity" to baseOpacity,
                                "grainOpacity" to grainOpacity,
                                "tintOpacity" to tintOpacity
                            ))
                    }
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        val filter = android.content.IntentFilter("com.example.film_vibes.UPDATE_OVERLAY")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(updateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(updateReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(updateReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
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
