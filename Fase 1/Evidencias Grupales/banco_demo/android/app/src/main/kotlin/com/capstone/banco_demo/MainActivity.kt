package com.capstone.banco_demo

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.capstone.banco_demo/notificaciones"
    private val notificationChannelId = "transacciones_demo"
    private val permissionRequestCode = 7001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tienePermisoNotificaciones" -> result.success(hasNotificationPermission())
                    "solicitarPermisoNotificaciones" -> requestNotificationPermission(result)
                    "enviarNotificacion" -> sendNotification(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission()) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), permissionRequestCode)
        }
        result.success(null)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId,
                "Transacciones de prueba",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Notificaciones emitidas por Banco Demo para pruebas"
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun sendNotification(call: MethodCall, result: MethodChannel.Result) {
        if (!hasNotificationPermission()) {
            result.error("PERMISO_DENEGADO", "Permiso de notificaciones no concedido", null)
            return
        }

        val id = call.argument<Int>("id")
        val title = call.argument<String>("titulo")
        val message = call.argument<String>("mensaje")
        if (id == null || title.isNullOrBlank() || message.isNullOrBlank()) {
            result.error("DATOS_INVALIDOS", "Faltan datos para crear la notificación", null)
            return
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, notificationChannelId)
        } else {
            @Suppress("DEPRECATION")
            android.app.Notification.Builder(this)
        }

        val notification = builder
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(android.app.Notification.BigTextStyle().bigText(message))
            .setAutoCancel(true)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, notification)
        result.success(null)
    }
}
