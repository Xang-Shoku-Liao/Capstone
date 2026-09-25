package com.example.finanzas_app

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val DETECTOR_CHANNEL = "com.capstone.finanzas_app/detector"
        const val ACTION_TRANSACTION_REGISTERED =
            "com.capstone.finanzas_app.TRANSACTION_REGISTERED"
    }

    private lateinit var detectorChannel: MethodChannel
    private var receiverRegistered = false

    private val transactionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_TRANSACTION_REGISTERED) {
                detectorChannel.invokeMethod("transaccionAutomaticaRegistrada", null)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        detectorChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DETECTOR_CHANNEL,
        )
        detectorChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "abrirAjustesDetector" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "detectorActivo" -> result.success(isDetectorEnabled())
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        val filter = IntentFilter(ACTION_TRANSACTION_REGISTERED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(transactionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(transactionReceiver, filter)
        }
        receiverRegistered = true
    }

    override fun onStop() {
        if (receiverRegistered) {
            unregisterReceiver(transactionReceiver)
            receiverRegistered = false
        }
        super.onStop()
    }

    private fun isDetectorEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val componentName = ComponentName(this, TransactionNotificationListenerService::class.java)
        return enabledListeners.split(':').any { item ->
            ComponentName.unflattenFromString(item) == componentName
        }
    }
}
