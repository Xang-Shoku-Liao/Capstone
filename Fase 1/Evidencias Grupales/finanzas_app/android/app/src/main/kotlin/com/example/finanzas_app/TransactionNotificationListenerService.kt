package com.example.finanzas_app

import android.app.Notification
import android.content.ComponentName
import android.content.ContentValues
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Detecta exclusivamente las notificaciones emitidas por Banco Demo durante
 * pruebas. No procesa mensajes de bancos reales ni de otras aplicaciones.
 */
class TransactionNotificationListenerService : NotificationListenerService() {
    companion object {
        private const val BANK_DEMO_PACKAGE = "com.capstone.banco_demo"
        private const val PREFS_NAME = "detector_transacciones"
        private const val PROCESSED_KEYS = "notificaciones_procesadas"
        private const val MAX_PROCESSED_KEYS = 100
        private val amountPattern = Regex(
            """(?:Compra aprobada por|Abono recibido por)\s*\$\s*([0-9.]+(?:,[0-9]{1,2})?)""",
            RegexOption.IGNORE_CASE,
        )
        private val receivedTransferPattern = Regex(
            """has recibido una transferencia de\s+(.+?)\s+por\s+\$\s*([0-9.]+(?:,[0-9]{1,2})?)\s+a\s+tu\s+cuentarut""",
            RegexOption.IGNORE_CASE,
        )
        private val sentTransferPattern = Regex(
            """has realizado una transferencia a\s+(.+?)\s+por\s+\$\s*([0-9.]+(?:,[0-9]{1,2})?)""",
            RegexOption.IGNORE_CASE,
        )
    }

    override fun onNotificationPosted(notification: StatusBarNotification) {
        if (notification.packageName != BANK_DEMO_PACKAGE) return

        val key = notification.key
        if (wasAlreadyProcessed(key)) return

        val message = notification.notification.extras
            .getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?.toString()
            ?.takeIf { it.isNotBlank() }
            ?: notification.notification.extras
                .getCharSequence(Notification.EXTRA_TEXT)
                ?.toString()
                ?.takeIf { it.isNotBlank() }
            ?: return

        val transaction = parseTransaction(message) ?: return
        if (saveTransaction(transaction)) {
            markAsProcessed(key)
            sendBroadcast(
                Intent(MainActivity.ACTION_TRANSACTION_REGISTERED).setPackage(packageName),
            )
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        requestRebind(
            ComponentName(this, TransactionNotificationListenerService::class.java),
        )
    }

    private fun parseTransaction(message: String): DetectedTransaction? {
        sentTransferPattern.find(message)?.let { transferMatch ->
            val amount = transferMatch.groupValues[2]
                .replace(".", "")
                .replace(',', '.')
                .toDoubleOrNull()
                ?: return null
            return DetectedTransaction(
                amount = amount,
                type = "gasto",
                category = "Otro",
                description = "Transferencia enviada: ${transferMatch.groupValues[1].trim()}",
            )
        }

        receivedTransferPattern.find(message)?.let { transferMatch ->
            val amount = transferMatch.groupValues[2]
                .replace(".", "")
                .replace(',', '.')
                .toDoubleOrNull()
                ?: return null
            return DetectedTransaction(
                amount = amount,
                type = "ingreso",
                category = "Otro ingreso",
                description = "Transferencia recibida: ${transferMatch.groupValues[1].trim()}",
            )
        }

        val amountMatch = amountPattern.find(message) ?: return null
        val amount = amountMatch.groupValues[1]
            .replace(".", "")
            .replace(',', '.')
            .toDoubleOrNull()
            ?: return null

        return when {
            message.startsWith("Compra aprobada por", ignoreCase = true) -> {
                val merchant = message.substringAfter(" en ", "Compra Banco Demo")
                    .trim()
                    .trimEnd('.')
                DetectedTransaction(
                    amount = amount,
                    type = "gasto",
                    category = categoryForExpense(merchant),
                    description = merchant,
                )
            }
            message.startsWith("Abono recibido por", ignoreCase = true) -> {
                val detail = message.substringAfter(":", "Abono Banco Demo")
                    .trim()
                    .trimEnd('.')
                DetectedTransaction(
                    amount = amount,
                    type = "ingreso",
                    category = if (detail.contains("sueldo", ignoreCase = true)) "Sueldo" else "Otro ingreso",
                    description = detail,
                )
            }
            else -> null
        }
    }

    private fun categoryForExpense(merchant: String): String {
        return when {
            merchant.contains("supermercado", ignoreCase = true) -> "Comida"
            merchant.contains("transporte", ignoreCase = true) -> "Transporte"
            else -> "Otro"
        }
    }

    private fun saveTransaction(transaction: DetectedTransaction): Boolean {
        val databaseFile = File(getDatabasePath("finanzas.db").path)
        if (!databaseFile.exists()) return false

        var database: SQLiteDatabase? = null
        return try {
            database = SQLiteDatabase.openDatabase(
                databaseFile.path,
                null,
                SQLiteDatabase.OPEN_READWRITE,
            )
            val categoryId = findCategoryId(database, transaction.category, transaction.type)
                ?: return false
            val values = ContentValues().apply {
                put("categoria_id", categoryId)
                put("monto", transaction.amount)
                put("fecha", SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()))
                put("descripcion", transaction.description)
                put("tipo", transaction.type)
                put("origen", "automatico")
                put("estado", "confirmado")
                put("institucion", "Banco Demo")
                put("hora", SimpleDateFormat("HH:mm:ss", Locale.US).format(Date()))
            }
            database.insertOrThrow("transaccion", null, values) != -1L
        } catch (_: Exception) {
            false
        } finally {
            database?.close()
        }
    }

    private fun findCategoryId(
        database: SQLiteDatabase,
        categoryName: String,
        type: String,
    ): Int? {
        database.rawQuery(
            "SELECT id FROM categoria WHERE nombre = ? AND tipo = ? LIMIT 1",
            arrayOf(categoryName, type),
        ).use { cursor ->
            return if (cursor.moveToFirst()) cursor.getInt(0) else null
        }
    }

    private fun wasAlreadyProcessed(key: String): Boolean {
        return getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .getStringSet(PROCESSED_KEYS, emptySet())
            ?.contains(key)
            ?: false
    }

    private fun markAsProcessed(key: String) {
        val preferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val keys = preferences.getStringSet(PROCESSED_KEYS, emptySet())
            ?.toMutableList()
            ?: mutableListOf()
        keys.remove(key)
        keys.add(key)
        preferences.edit()
            .putStringSet(PROCESSED_KEYS, keys.takeLast(MAX_PROCESSED_KEYS).toSet())
            .apply()
    }

    private data class DetectedTransaction(
        val amount: Double,
        val type: String,
        val category: String,
        val description: String,
    )
}
